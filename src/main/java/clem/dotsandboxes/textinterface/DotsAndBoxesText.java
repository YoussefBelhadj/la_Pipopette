package clem.dotsandboxes.textinterface;

import static com.google.common.base.Preconditions.checkArgument;
import static com.google.common.base.Preconditions.checkNotNull;
import clem.dotsandboxes.DefaultGame;
import clem.dotsandboxes.DefaultGameState;
import clem.dotsandboxes.Edge;
import clem.dotsandboxes.Game;
import clem.dotsandboxes.GameState;
import clem.dotsandboxes.Player;
import clem.dotsandboxes.prolog.PrologRunner;
import clem.dotsandboxes.prolog.SicstusPrologRunner;
import clem.dotsandboxes.prolog.SwiPrologRunner;
import clem.dotsandboxes.prolog.Utils;
import clem.util.Pair;

import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.util.Arrays;
import java.util.List;
import java.util.Random;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.SystemUtils;

import uk.co.flamingpenguin.jewel.cli.ArgumentValidationException;
import uk.co.flamingpenguin.jewel.cli.Cli;
import uk.co.flamingpenguin.jewel.cli.CliFactory;

import com.google.common.base.Preconditions;
import com.google.common.collect.ImmutableList;

public class DotsAndBoxesText {
	
	public static void main(String[] args) throws IOException {
		
		Options options;
		
		try {
			Cli<Options> cli = CliFactory.createCli(Options.class);
			
			/*
			args = new String[]{
					"--player-one-type", "java",
					"--player-two-type", "prolog",
					"--prolog-executable", "C:\\Program Files (x86)\\SICStus Prolog 3.11.1\\bin\\sicstus.exe",
					"--prolog-type", "sicstus",
					"--p2-lookahead", "4",
					"--p1-lookahead", "4",
					"--width", "4",
					"--height", "4",
					"--yes"
			};
			//*/
			
			if(Arrays.asList(args).contains("--help")) {
				System.out.println(cli.getHelpMessage());
				System.exit(0);
			}
			
			options = cli.parseArguments(args);
		} 
		catch (ArgumentValidationException e) {
			System.err.println(e.getMessage());
			System.exit(1);
			throw new AssertionError("never happens");
		}
		
		// Lance le jeu
		ImmutableList<Player> players = Players.makePlayers(options);
		Preconditions.checkState(players.size() == 2, "unexpected player " +
				"count received from Players.makePlayers");
		Player p1 = players.get(0);
		Player p2 = players.get(1);
		
		new DotsAndBoxesText(options.getWidth(), options.getHeight(), p1, p2,
				options.getBoardRepresentation().getPrinter(), 
				options.getAlwaysShowBoardAndContinue())
			.play();
	}

	private final int mOutWidth = 80;
	
	private final PrintStream mOut = System.out;
	
	private final int mBoardWidth;
	private final int mBoardHeight;
	
	private final Game mGame;
	
	private final Player mPlayer1;
	
	private final Player mPlayer2;
	
	private final GameGridPrinter mPrinter;
	
	private static final Random RANDOM = new Random();
	
	private final boolean mAlwaysShowBoard;
	
	public DotsAndBoxesText(int width, int height, Player p1, Player p2, 
			GameGridPrinter printer, boolean alwaysShowBoard) {
		checkNotNull(p1, "player1 was null");
		checkNotNull(p2, "player2 was null");
		checkArgument(width > 1, "width was < 2");
		checkArgument(height > 1, "height was < 2");
		checkArgument(!p1.equals(p2), "player 1 and 2 are the same");
		checkNotNull(printer);
		
		mPlayer1 = p1;
		mPlayer2 = p2;
		
		mBoardWidth = width;
		mBoardHeight = height;
		
		mGame = DefaultGame.INSTANCE;
		mPrinter = printer;
		
		mAlwaysShowBoard = alwaysShowBoard;
	}
	
	public void play() {
		
		// Affiche le titre et saute une ligne
		mOut.println(StringUtils.center(Values.TITLE, mOutWidth));
		mOut.println(StringUtils.center(StringUtils.repeat(
				Values.TITLE_UNDERSCORE, Values.TITLE.length()), mOutWidth));
		mOut.println();
		
		// Print a message introducing the game
		mOut.println(Values.INTRO_MSG);
		mOut.println();
		
		// Identification des deux joueurs
		printPlayerAnnounce();
		mOut.println();
		
		// Choix de l'ordre de jeu al�atoire
		final List<Player> players = RANDOM.nextBoolean() ? 
				ImmutableList.of(mPlayer1, mPlayer2) :
				ImmutableList.of(mPlayer2, mPlayer1);
		
		GameState state = DefaultGameState.get(mBoardWidth, mBoardHeight, 
				players);
		
		int turn = 1;
		
		while(!mGame.isGameCompleted(state)) {
			
			// Qui joue apr�s ?
			final Player next = mGame.getNextPlayer(state);
			
			// Affiche le message du tour
			mOut.format(Values.TURN_START + "\n", turn, next.getName());
			
			// Changement de joueur
			GameState newState = mGame.nextMove(state);
			
			// R�sultat du tour
			Edge move = newState.getNewestEdge();
			mOut.format(Values.TURN_RESULT, next.getName(),
					move.getCanX(), move.getCanY(), 
					move.getCanDirection().toString());
			
			// Affiche un message si un carr� est effectu�
			switch(newState.getCompletedCellCount() - 
					state.getCompletedCellCount()) {
				case 1: mOut.print(Values.TURN_RESULT_COMPLETED_1);
					break;
				case 2: mOut.print(Values.TURN_RESULT_COMPLETED_2);
					break;
			}
			
			boolean gameOver = mGame.isGameCompleted(newState);
			if(!gameOver) {
				// Demander � afficher le jeu
				mOut.print(Values.PROMPT_SHOW_BOARD);
				
				// R�ponse oui automatique
				if(mAlwaysShowBoard) 
					mOut.print("yes");
			}
			if(mAlwaysShowBoard || gameOver || 
					InputUtils.askYesNoQuestion(System.in, false)) {
				mOut.println(); // Masquer la saisie du joueur
				mOut.println();
				printBoard(newState);
			}
			else {
				mOut.println();
				mOut.println();
			}
			
			state = newState;
			++turn;
		}
		Player p1 = state.getPlayers().get(0);
		Player p2 = state.getPlayers().get(1);
		int score1 = mGame.getScore(state, p1);
		int score2 = mGame.getScore(state, p2);
		
		if(score1 == score2)
			mOut.println(Values.RESULT_DRAW);
		else
			mOut.println(String.format(Values.RESULT_WINNER, (score1 > score2 ? 
					p1 : p2).getName()));
		
		// Affiche le score final
		mOut.format(Values.SCORE + "\n", p1.getName(), 
				mGame.getScore(state, p1));
		mOut.format(Values.SCORE + "\n", p2.getName(), 
				mGame.getScore(state, p2));
	}
	
	/**
	 *  
	 * @param str The string to centre.
	 * @param width The width of the area to centre the string in.
	 * @return The left and right padding required.
	 */
	private static Pair<Integer, Integer> centerPad(String str, int width) {
		return centerPad(str.length(), width);
	}
	
	/**
	 *  
	 * @param strWidth The width of the string to centre.
	 * @param width The width of the area to centre the string in.
	 * @return The left and right padding required.
	 */
	private static Pair<Integer, Integer> centerPad(int strWidth, 
			int width) {
		Preconditions.checkArgument(strWidth >= 0, "strWidth must be positive");
		final int totalPad = Math.max(0, width - strWidth);
		
		return Pair.of(
				totalPad / 2, 
				totalPad % 2 == 0 ? totalPad / 2 : (totalPad / 2) + 1);
	}
	
	/**
	 *  
	 * @param availableWidth
	 * @param name
	 * @param score
	 * @return
	 */
	private static String makeScoreStr(int availableWidth, String name, 
			int score) {
		
		String min = String.format(Values.SCORE, "", score);
		int nameSpace = Math.max(0, availableWidth - min.length());
		
		String compressedName = StringUtils.abbreviate(name, nameSpace);
		final String out = String.format(Values.SCORE, compressedName, score);
		
		return out;
	}
	
	private String makeScoreAndTitleUnderlineLine(GameState gamestate) {
		
		Preconditions.checkArgument(gamestate.getPlayers().size() == 2, 
				"Two players expected in gamestate.");
		
		Player p1 = gamestate.getPlayers().get(0);
		int p1Score = mGame.getScore(gamestate, p1);
		Player p2 = gamestate.getPlayers().get(1);
		int p2Score = mGame.getScore(gamestate, p2);
		
		final String underline = StringUtils.repeat(
				Values.TITLE_UNDERSCORE, Values.SHOW_BOARD_TITLE.length());
		final Pair<Integer, Integer> pad = centerPad(underline, mOutWidth);
		
		String p1Str = makeScoreStr(pad.first() - 1, p1.getName(), p1Score);
		String p2Str = makeScoreStr(pad.second() - 1, p2.getName(), p2Score);
		
		return StringUtils.rightPad(p1Str, pad.first() - 1) 
				+ " " + underline + " " 
				+ StringUtils.leftPad(p2Str, pad.second() - 1);
	}
	
	private String makeTitleLine() {
		final Pair<Integer, Integer> pad = centerPad(Values.SHOW_BOARD_TITLE, 
				mOutWidth);
		return StringUtils.repeat(" ", pad.first()) + Values.SHOW_BOARD_TITLE + 
			StringUtils.repeat(" ", pad.second());
	}
	
	private void printBoard(GameState state) {
		
		mOut.println(makeTitleLine());
		mOut.println(makeScoreAndTitleUnderlineLine(state));
		mOut.println();
		mPrinter.printState(state, mOut);
		mOut.println();
	}
	
	private void printPlayerAnnounce() {
		String left = String.format(Values.PLAYER_ANNOUNCE, 
				1, mPlayer1.getName(), mPlayer1.getDecisionEngine().getName());
		
		String right = String.format(Values.PLAYER_ANNOUNCE, 
				2, mPlayer2.getName(), mPlayer2.getDecisionEngine().getName());
		
		String middle = Values.PLAYER_ANNOUNCE_SEPARATOR;
		
		int len = left.length() + middle.length() + right.length();
		int pad = Math.max(2, mOutWidth - len);
		
		final int padLeft, padRight;
		
		if(pad % 2 == 0)
			padLeft = padRight = pad / 2;
		else {
			padLeft = pad / 2; padRight = padLeft + 1;
		}
		
		mOut.println(left + 
				   StringUtils.repeat(" ", padLeft) + 
				   middle + 
				   StringUtils.repeat(" ", padRight) + 
				   right);
	}
}
