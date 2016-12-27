package clem.dotsandboxes.decision;

import clem.dotsandboxes.Edge;
import clem.dotsandboxes.Game;
import clem.dotsandboxes.GameState;
import clem.dotsandboxes.Player;

public interface DecisionEngine {
	
	 Edge makeMove(GameState gameState, Player player, Game game);
	 
	 String getName();
}
