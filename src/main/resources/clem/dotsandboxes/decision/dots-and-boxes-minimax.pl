/*
 * Ce fichier Implémente le jeu La Pipopipette en minmax
 *
 * La Pipopipette ou « jeu des petits carrés » est un jeu de société se pratiquant
 * à deux joueurs en tour par tour. Le jeu se joue généralement avec papier et 
 * crayon sur du papier quadrillé. Mais il existe aussi des versions en boîte.
 * À chaque tour, chaque joueur trace un petit trait suivant le quadrillage de la 
 * feuille. Le but du jeu est de former des carrés. Le gagnant est celui qui a fermé 
 * le plus de carrés. Le fait de fermer un carré impose de rejouer, ce qui peut aboutir 
 * à fermer de nombreux carrés à la suite lorsque se créent des couloirs.
 * 
 * Pour plus d'informations : 
 * https://fr.wikipedia.org/wiki/La_Pipopipette
 * 
 *
 * @author Youssef Belhadj
 */

% Importe certaines bibliothèques utilisées par le code. 
% J'utilise AVL tree library Java.
:- use_module(library(assoc)).

% J'ai ici utilisé Sicstus 4.3.5 dont voici la documentation : https://sicstus.sics.se/documentation.html
% j'ai également dû ré-implémenter la map-list (en bas de la page)

%:- use_module(library(apply)).

% Utilise les listes de la librairie 
:- use_module(library(lists)).
% Si plusieurs solutions sont optimales, nous choisirons aléatoirement l'une des solutions 
% La librairie propose ça
:- use_module(library(random)).

% Les tests concerants la décisions commencent ici (partie importante du projet)
% Lire les différents println pour comprendre les paramètres (1,2,3 et 4) 

minimax_test(1):-
	println(['This should result in a random edge chosen each time it\'s run.']),
	Moves = [
	],
	state_with(8, 8, Moves, [p1, p2], State),
	
	time_(minimax(State, p1, 1, Move)),
	Move = move(_, edge(_, _, _)), 
	println([Move]).

minimax_test(2):-
	% List of edge-player pairs to add to the gamestate before running
	Moves = [
	    edge(0, 0, right)-p1,
	    edge(0, 0, down)-p2,
	    edge(1, 0, down)-p1,
	    edge(0, 1, right)-p2,
	    
	    edge(1, 1, right)-p2,
	    edge(1, 1, down)-p1,
	    edge(2, 1, down)-p2
	],
	state_with(5, 5, Moves, [p1, p2], State),
	
	time_(minimax(State, p1, 1, Move)),
	Move = move(_, edge(1, 2, right)), 
	println([Move]).

minimax_test(3):-
	println(['This takes about 2 minutes to finish on my machine.']),
	Moves = [
	    edge(0, 0, right)-p1,
	    edge(0, 0, down)-p2,
	    edge(1, 0, down)-p1,
	    edge(0, 1, right)-p2,
	    
	    edge(1, 1, right)-p2,
	    edge(1, 1, down)-p1,
	    edge(2, 1, down)-p2
	],
	state_with(4, 4, Moves, [p1, p2], State),
	
	time_(minimax(State, p1, 5, Move)),
	Move = move(_, edge(1, 2, right)), 
	println([Move]).

minimax_test(4):-
	println(['This test uses a very high max depth to force a search of ',
		 'all possible games for a small board.']),
	Moves = [
	],
	state_with(3, 2, Moves, [p1, p2], State),
	
	time_(minimax(State, p1, 100, Move)),
	println([Move]).

% Calcul du temps pris par le PC pour trouver la solution optimale 
$ J'ai utilisé la métode prolog statistics (voir les paramètres ici : http://www.swi-prolog.org/pldoc/man?predicate=statistics/2)
time_(Goal):-
	statistics(walltime, _),
	statistics(runtime, _),
	Goal,
	statistics(runtime, [_|RunMillis]),
	statistics(walltime, [_|WallMillis]),
	RunTime is RunMillis / 1000.0,
	WallTime is WallMillis / 1000.0,
	println(['Wall time:', WallTime, 'seconds, Run time:', RunTime]).


% Affichage, tout simplement 
println(List):-
	println(List, ' ').
println([], _):-nl.
println([Head|Tail], Separator):-
	write(Head), write(Separator), println(Tail).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These predicates are used for main()...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% state_with(+Width, +Height, +EdgePlayerPairs, +Players, -State)
%
% State is a gamestate with the given features.
%
% EdgePlayerPairs if a list of edge-player pairs of the form:
% 
% [edge(0,1,right)-p1|_]
%
state_with(Width, Height, EdgePlayerPairs, Players, State):-
	empty_game_state(Width, Height, Players, EmptyState),
	state_with_edges(EmptyState, EdgePlayerPairs, State).

%% state_with_edges(+State, +Edges, -StateWithEdges)
%
% StateWithEdges is State with the list of Edges added.
%
state_with_edges(State, [], State).
state_with_edges(State, [Edge-Player|Rest], StateWithEdges):-
	state_put_edge(State, Edge, Player, NewState),
	state_with_edges(NewState, Rest, StateWithEdges).

main(Width, Height, EdgePlayerPairs, SearchDepth, Players):-
	state_with(Width, Height, EdgePlayerPairs, Players, State),
	next_player(State, FavoredPlayer),
	
	% Run minimax, handling any errors (e.g. out of memory conditions)
	catch(minimax(State, FavoredPlayer, SearchDepth, move(Score, Edge)), 
	      Error, handle_error(Error)),
	
	write(move(Score, Edge)).

handle_error(Error):-
	error_message(Error, Message),
	write(user_error, 'Error occoured running minimax: '), 
	write(user_error, Message), 
	write(user_error, '\n'),
	clemt(3).

error_message(resource_error(0,memory), 'Resource error: insufficient memory').
error_message(Error, Error).

/*
 * Le code suivant est la mise en œuvre de minimax 
 * avec des prédicats de soutien pour travailler 
 * avec les règles de la Pipopipette
 */

% Les directions
direction(right).
direction(down).

% Les joueurs
player(p1).
player(p2).


empty_game_state(Width, Height, Players, State):-
	State = gamestate(Width, Height, Edges, Players),
	empty_assoc(Edges),
	Players = [P1|[P2]], player(P1), player(P2), P1 \= P2.


%% edge_in_game(+Width, +Height, -Edge)
%
% Énumère les bords disponibles dans l'état actuel du jeu en fonction de la hauteur
% et de la largeur donnée

edge_in_game(Width, Height, Edge) :-
	Edge = edge(X, Y, down), 
	in_range(0, Width, X), 
	YLimit is Height - 1, in_range(0, YLimit, Y).
edge_in_game(Width, Height, Edge) :-
	Edge = edge(X, Y, right), 
	XLimit is Width - 1, in_range(0, XLimit, X), 
	in_range(0, Height, Y).


%% state_open_edge(+State, -Edge)
% 
% Donne l'état du bord (ouvert si il n'a pas été ajouté)
% 
state_open_edge(State, Edge) :-
	State = gamestate(Width, Height, Edges, _),
	edge_in_game(Width, Height, Edge),
	(get_assoc(Edge, Edges, edge_data(player(_), age(_))) ->
		fail ; true).


%% state_closed_edge(+State, -Edge, -EdgeData)
% 
%  Donne l'état du bord (fermé si il a été ajouté)
% 
state_closed_edge(State, Edge, EdgeData) :-
	State = gamestate(Width, Height, Edges, _),
	edge_in_game(Width, Height, Edge),
	get_assoc(Edge, Edges, EdgeData).


%% state_put_edge(+GameState, +Edge, +Player, -NewState)
% 
% Ajoute une ligne et l'associe au joueur. NewSate sera le gamestate
% d'entré avec la ligne ajoutée (voir méthodes du dessus
state_put_edge(GameState, Edge, Player, NewState) :-
	% break up the gamestate
	GameState = gamestate(Width, Height, Edges, Players),
	
	% Assure que player est un joueur (corrige des problèmes qui laissaient l'ordinateur jouer
	% contre lui même
	player(Player), member(Player, Players),
	
	% Assure que la ligne fasse bien parti du plateau
	edge_in_game(Width, Height, Edge),
	
	(newest_edge(GameState, _, edge_data(_, age(NewestAge))) ->
		Age is NewestAge + 1 ;
		Age is 0),
	
	put_assoc(Edge, Edges, edge_data(player(Player), age(Age)), NewEdges),
	
	% Met à jour les données avec la nouvelle ligne 
	NewState = gamestate(Width, Height, NewEdges, Players), !.


%% in_range(+Min, +Max, ?N)
% 
% Énumère les entiers entre Min et Max. N est un entier >= Min et < Max.
%
in_range(Min, Max, N) :- Min < Max, N = Min.
in_range(Min, Max, N) :- 
	NextMin is Min + 1, NextMin < Max, in_range(NextMin, Max, N).

%% minimax(+GameState, +FavoredPlayer, +Depth, -Result)
%
% Result est sous la forme (score, edge(x, y, direction))
%

minimax(GameState, FavoredPlayer, Depth, Result) :-
	% Pour chaque déplacement possible (à cette profondeur)
	% On génère un nouvel état de jeu
	
	% Il faut que death > 0
	Depth > 0,
	
	% Trouve quel joueur joue ce tour ci
	next_player(GameState, Player),
	
	% Récupérer toutes les lignes possibles du tour
	findall(Edge, state_open_edge(GameState, Edge), Edges),
	
	% Evaluer tout les mouvement possibles à ce stade 
	% et collecter move(Edge, Score)
	% dans une liste
	map_tr(apply_edge(GameState, FavoredPlayer, Depth, Player),
		Edges, % The list of possible edges
		Moves), % A will be a list of move(Edge, Score) elements
	
	% On trie les mouvements par score
	sort(Moves, SortedMoves),
	
	% Ici on décide de quel score retourner (résultat du minmax.
	% Si deux scores sont identiques, on choisira aléatoirement l'un des deux
	(FavoredPlayer == Player ->
		% Si le joueur en cours est celui pour lequel la décision doit être prise,
		% on choisi alors le score le plus haut avec le mouvement qui lui correspond
		last(SortedMoves, move(TargetScore, _)) ;
		% Dans le cas contraire, on imagine que le l'adversaire va choisir le pire score pour
		% nous, donc on choisi le score le plus bas
		[move(TargetScore, _)|_] = SortedMoves), 
	
	% Obtenir une liste contenant les solution optimales
	filter(move_with_score(TargetScore), SortedMoves, OptimalMoves),
	
	% Sélectionnez un élément aléatoire parmi les mouvements optimaux
	% et l'associer avec le résultat (Result)
	random_element(OptimalMoves, Result), !.

minimax(GameState, FavoredPlayer, 0, move(Score, _)) :-
	% Lorsque la profondeur est de 0, nous de pouvons pas continuer à cherchez
	% l'état des enfants (du coup d'après dans l'arbre), nous n'avons donc qu'à 
	% choisir la meilleure solution possible. 
	evaluate_board(GameState, FavoredPlayer, Score), !.

minimax(GameState, FavoredPlayer, _, move(Score, _)) :-
	% Plus de mouvements possibles
	no_moves_left(GameState),
	evaluate_board(GameState, FavoredPlayer, Score), !.

%% apply_edge(+GameState, +FavoredPlayer, +CallerDepth, +Player, +Edge, -Result)
% 
% Créer le nouvel état en y ajoutant le dernier résultat donnant
%le score ainsi que le mouvement effectué
%
apply_edge(GameState, FavoredPlayer, CallerDepth, Player, Edge, Result):-
	Depth is CallerDepth - 1,
	
	% Créer le nouvel étant en y ajoutant le bord joué 
	state_put_edge(GameState, Edge, Player, NewState),
	
	% minmax sur le nouvel etat
	minimax(NewState, FavoredPlayer,  Depth, move(Score, _)),
	Result = move(Score, Edge).

move_with_score(Score, move(Score, _)).

%% evaluate_board(+GameState, +FavoredPlayer, -Score)
%
%
evaluate_board(GameState, FavoredPlayer, Score) :-
	GameState = gamestate(Width, Height, _, [P1|[P2|_]]),
	
	MaxScore is (Width - 1) * (Height - 1),
	
	cell_count(GameState, P1, P1Score),
	cell_count(GameState, P2, P2Score),
	
	(FavoredPlayer = P1 ->
		Score is (P1Score - P2Score) / (MaxScore / 2.0) ;
		Score is (P2Score - P1Score) / (MaxScore / 2.0)).


%% no_moves_left(+GameState)
% 
% Vrai si il n'y a plus de mouvement disponibles (fin du jeu)
% 
no_moves_left(GameState):-
	GameState = gamestate(Width, Height, _, _),
	% Trouver le maximum de bord (ligne) que le plateau puisse contenir
	max_edge_count(Width, Height, MaxEdges),
	
	% Nombre de bord dans l'état
	edge_count(GameState, EdgeCount),
	
	% Le plateau est-il complet ?
	EdgeCount >= MaxEdges.


%% next_player(+GameState, -Player)
%
% Donne au joueur le prochain mouvement à fairecompte tenu de l'état de jeu.
%
next_player(GameState, Player):-
	edge_count(GameState, 0),
	GameState = gamestate(_, _, _, [Player|_]).
next_player(GameState, Player):-
	previous_player(GameState, PreviousPlayer),
	(newest_edge_completed_cell(GameState, _, _) ->
		% Le joueur préçédent à completé un carré, il doit donc rejouer
		Player = PreviousPlayer ;

		GameState = gamestate(_, _, _, [P1|[P2|_]]),
		(PreviousPlayer = P1 -> Player = P2 ; Player = P1)).
		

%% previous_player(+GameState, -Player)
%
% Le joueur précédent à jouer est le joueur qui a ajouté le bord le plus récent.
%
previous_player(GameState, Player):-
	newest_edge(GameState, _, edge_data(player(Player), _)).

cell_uses_edge(GameState, edge(X, Y, down), Cell):-
	XMinus1 is X - 1,
	Cell = cell(XMinus1, Y),
	cell_completed_in_state(GameState, Cell, _, _).
cell_uses_edge(GameState, edge(X, Y, right), Cell):-
	YMinus1 is Y - 1,
	Cell = cell(X, YMinus1),
	cell_completed_in_state(GameState, Cell, _, _).
cell_uses_edge(GameState, edge(X, Y, _), Cell):-
	Cell = cell(X, Y),
	cell_completed_in_state(GameState, Cell, _, _).

newest_edge_completed_cell(GameState, Edge, Cell):-
	newest_edge(GameState, Edge, _),
	cell_uses_edge(GameState, Edge, Cell).

newest_edge(GameState, Edge, EdgeData):-
	GameState = gamestate(_, _, Edges, _),
	assoc_to_list(Edges, EdgeList),
	EdgeList = [First|_],
	newest_edge_(EdgeList, First, Edge-EdgeData).

newest_edge_([], CurrentLargest, Largest):- CurrentLargest = Largest.
newest_edge_([Head|Rest], CurrentLargest, Largest):-
	Head = _-edge_data(_, age(HeadAge)),
	CurrentLargest = _-edge_data(_, age(Age)),
	(HeadAge > Age ->
		newest_edge_(Rest, Head, Largest) ;
		newest_edge_(Rest, CurrentLargest, Largest)).
		


%% max_edge_count(+Width, +Height, -Count)
%
% Compte le nombre de ligne possible en fonction de la taille du plateau
%
max_edge_count(Width, Height, Count):-
	Count is 2 * (Width - 1) * (Height - 1) + (Width - 1) + (Height - 1).


%%
%
% 
%
edge_count(GameState, Count):-
	GameState = gamestate(_, _, Edges, _),
	assoc_to_list(Edges, EdgeList), length(EdgeList, Count).


%% cell_in_grid(?Width, ?Height, ?Cell)
%
% Réussi si le carré existe dans le plateau aux dimentions données
%

cell_in_grid(Width, Height, Cell):-
	in_range(0, Width, X),
	in_range(0, Height, Y),
	Cell = cell(X, Y).


%% cell_completed_in_state(+GameState, ?Cell, ?CompletingEdge, 
%                          ?CompletingEdgeData)
%
% Réussi si le carré est complet (4 bords)
%
cell_completed_in_state(GameState, Cell, CompletingEdge, CompletingEdgeData):-
	GameState = gamestate(Width, Height, _, _),
	cell_in_grid(Width, Height, Cell),
	Cell = cell(X, Y),
	XPlus1 is X + 1, YPlus1 is Y + 1,
	
	Edge1 = edge(X, Y, right), 
	edge_in_gamestate(GameState, Edge1, Data1),
	
	Edge2 = edge(X, Y, down), 
	edge_in_gamestate(GameState, Edge2, Data2),
	
	Edge3 = edge(X, YPlus1, right), 
	edge_in_gamestate(GameState, Edge3, Data3),
	
	Edge4 = edge(XPlus1, Y, down), 
	edge_in_gamestate(GameState, Edge4, Data4),
	
	oldest_edge(Edge1-Data1, Edge2-Data2, Edge3-Data3, Edge4-Data4, 
		CompletingEdge-CompletingEdgeData).
	
oldest_edge(Edge1, Edge2, Edge3, Edge4, OldestEdge):-
	oldest_edge(Edge1, Edge2, Res1),
	oldest_edge(Edge3, Edge4, Res2),
	oldest_edge(Res1, Res2, OldestEdge).

oldest_edge(Edge1, Edge2, OldestEdge):-
	Edge1 = edge(_, _, _)-edge_data(_, age(Age1)),
	Edge2 = edge(_, _, _)-edge_data(_, age(Age2)),
	(Age1 > Age2 -> OldestEdge = Edge1 ; OldestEdge = Edge2).
	

%% edge_in_gamestate(+GameState, -Edge)
%
% Réussi si le bord existe dans le plate	u
% 
edge_in_gamestate(GameState, Edge, EdgeData):-
	GameState = gamestate(_, _, Edges, _),
	get_assoc(Edge, Edges, EdgeData).


cell_count(GameState, Player, Count):-
	findall(X, cell_completed_in_state(
		GameState, X, _, edge_data(player(Player), _)), Cells),
	length(Cells, Count).

%% random_element(+List, -Element).
%
% Element élément choisi aléatoiement dans la liste
%
random_element([], _):- fail.
random_element(List, Element):-
	length(List, Len),
	random(0, Len, RandomIndex),
	nth0(RandomIndex, List, Element), !.

/*
 * J'ai implémenté les prédicats suivants moi-même pour remplacer
 * la bibliothèque d'application que j'avais utilisé dans SWI / Sicstus4
 * quand j'ai découvert que Sicstus 3 ne fonctionnait pas.
 */

fold_left(Predicate, [Initial|List], Result):-
	foldl_(List, Predicate, Initial, Result).

fold_left(Predicate, Initial, List, Result):-
	foldl_(List, Predicate, Initial, Result).

foldl_([], _, Value, Result):-
	Value = Result.
foldl_([Head|Tail], Predicate, Value, Result):-
	call_n(Predicate, [Value, Head, NewValue]),
	foldl_(Tail, Predicate, NewValue, Result).

fold_right(Predicate, Initial, List, Result):-
	foldr_(List, Predicate, Initial, Result).
foldr_([], _, Value, Result):- Value = Result.
foldr_([Head|Tail], Predicate, Value, Result):-
	foldr_(Tail, Predicate, Value, TailResult),
	call_n(Predicate, [Head, TailResult, Result]).

map(Predicate, List, Result):-
	fold_right(map_apply(Predicate), [], List, Result).

map_apply(Predicate, Value, Rest, Result):-
	call_n(Predicate, [Value, OutValue]),
	cons_(OutValue, Rest, Result).

cons_(First, Rest, [First|Rest]).

plus_(A, B, Out):- Out is A + B.

call_n(Pred, ArgList):-
	Pred =.. Term,
	append(Term, ArgList, TermN),
	ToCall =.. TermN,
	call(ToCall).

reverse_(List, Reversed):-
	fold_left(flip_cons_, [], List, Reversed).

flip_cons_(A, B, Result):-
	cons_(B, A, Result).

fold_right_tr(Predicate, Initial, List, Result):-
	reverse_(List, Reversed),
	fold_left(call_flip_args_(Predicate), Initial, Reversed, Result).

call_flip_args_(Predicate, First, Second, Result):-
	call_n(Predicate, [Second, First, Result]).

map_tr(Predicate, List, Result):-
	fold_right_tr(map_apply(Predicate), [], List, Result).

filter(Predicate, List, Result):-
	fold_right_tr(filter_pred_(Predicate), [], List, Result).

filter_pred_(Predicate, Element, Rest, Out):-
	(call_n(Predicate, [Element])
		-> cons_(Element, Rest, Out)
		;  Rest = Out).

/*
 *
 * Le code à partir d'ici est uniquement pour des tests
 * d'exemples récupérés sur internet
 * 
 */

/*
:- use_module(library(plunit)).

:- begin_tests(higher).

% The result of a right folding a list with cons & the empty list as an initial
% value is the origional list.
test('foldr identity'):-
	List = [1, 2, 3, 4, 5, 6, 7, 8],
	fold_right(cons_, [], List, List).
test('foldr tr identity'):-
	List = [1, 2, 3, 4, 5, 6, 7, 8],
	fold_right_tr(cons_, [], List, List).

test('foldr addition'):-
	fold_right(plus_, 0, [1, 2, 3, 4, 5], 15).
test('foldr tr addition'):-
	fold_right_tr(plus_, 0, [1, 2, 3, 4, 5], 15).

test('foldl addition'):-
	fold_left(plus_, [1, 2, 3, 4, 5], 15).

test('foldl addition'):-
	fold_left(plus_, 0, [1, 2, 3, 4, 5], 15).

test('map'):-
	map(plus_(1), [1, 2, 3, 4, 5], [2, 3, 4, 5, 6]).

test('map_tr'):-
	map_tr(plus_(1), [1, 2, 3, 4, 5], [2, 3, 4, 5, 6]).

:- end_tests(higher).


:- begin_tests(minimax).
test(in_range) :- 
	in_range(-1, 10, 4), 
	%not(in_range(0, 10, -2)),
	%not(in_range(0, 10, 10)),
	in_range(-1, 10, 9).
	
test('Enumerate edges') :-
	findall(X, edge_in_game(3, 3, X), List), length(List, L), L = 12.

test('Edge Count 1') :-
	max_edge_count(3, 3, 12).
test('Edge Count 2') :-
	max_edge_count(4, 9, 59).
test('Edge Count 3') :-
	max_edge_count(5, 5, 40).

test('newest_edge'):-
	Oldest = edge(0, 1, down),
	empty_game_state(5, 5, [p1, p2], S1), 
	state_put_edge(S1, edge(0, 0, right), p1, S2),
	state_put_edge(S2, Oldest, p2, S3),
	newest_edge(S3, Oldest, edge_data(player(p2), age(1))).

test('oldest edge'):-
	Pair1 = edge(0, 0, right)-edge_data(player(p1), age(0)),
	Pair2 = edge(0, 0, right)-edge_data(player(p2), age(1)),
	oldest_edge(Pair1, Pair2, Pair2).

test('oldest edge'):-
	Pair1 = edge(0, 0, right)-edge_data(player(p1), age(0)),
	Pair2 = edge(0, 0, right)-edge_data(player(p2), age(1)),
	Pair3 = edge(0, 0, right)-edge_data(player(p2), age(3)),
	Pair4 = edge(0, 0, right)-edge_data(player(p2), age(4)),
	oldest_edge(Pair3, Pair1, Pair4, Pair2, Pair4).

test('cell completed in state'):-
	empty_game_state(3, 3, [p1, p2], S0), 
	state_put_edge(S0, edge(0, 0, right), p1, S1),
	state_put_edge(S1, edge(0, 0, down ), p2, S2),
	state_put_edge(S2, edge(1, 0, down ), p1, S3),
	state_put_edge(S3, edge(0, 1, right), p2, S4),
	cell_completed_in_state(S4, cell(0, 0), edge(0, 1, right), _).

test('cell_count 1'):-
	empty_game_state(3, 3, [p1, p2], S0),
	
	% Complete the cell(0, 0)
	state_put_edge(S0, edge(0, 0, right), p1, S1),
	state_put_edge(S1, edge(0, 0, down ), p2, S2),
	state_put_edge(S2, edge(1, 0, down ), p1, S3),
	state_put_edge(S3, edge(0, 1, right), p2, S4),
	
	cell_count(S4, p1, 0),
	cell_count(S4, p2, 1).

test('cell_count 2'):-
	empty_game_state(3, 3, [p1, p2], S0),
	
	% Complete the cell(0, 0)
	state_put_edge(S0, edge(0, 0, right), p1, S1),
	state_put_edge(S1, edge(0, 0, down ), p2, S2),
	state_put_edge(S2, edge(1, 0, down ), p1, S3),
	state_put_edge(S3, edge(0, 1, right), p2, S4),
	
	state_put_edge(S4, edge(1, 1, right), p2, S5),
	state_put_edge(S5, edge(1, 1, down ), p1, S6),
	state_put_edge(S6, edge(2, 1, down ), p2, S7),
	state_put_edge(S7, edge(1, 2, right), p1, S8),
	
	cell_count(S8, p1, 1),
	cell_count(S8, p2, 1).

test('minimax 2'):-
	empty_game_state(5, 5, [p1, p2], S0),
	
	% Complete the cell(0, 0)
	state_put_edge(S0, edge(0, 0, right), p1, S1),
	state_put_edge(S1, edge(0, 0, down ), p2, S2),
	state_put_edge(S2, edge(1, 0, down ), p1, S3),
	state_put_edge(S3, edge(0, 1, right), p2, S4),
	
	state_put_edge(S4, edge(1, 1, right), p2, S5),
	state_put_edge(S5, edge(1, 1, down ), p1, S6),
	state_put_edge(S6, edge(2, 1, down ), p2, S7),
	%state_put_edge(S7, edge(1, 2, right), p1, S8),
	
	minimax(S7, p1, 1, Move),
	Move = move(_, edge(1, 2, right)), write(Move).

:- end_tests(minimax).
%*/