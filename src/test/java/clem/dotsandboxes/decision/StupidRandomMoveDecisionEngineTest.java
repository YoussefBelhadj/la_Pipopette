package clem.dotsandboxes.decision;

import static org.junit.Assert.*;
import clem.dotsandboxes.DefaultGame;
import clem.dotsandboxes.DefaultGameState;
import clem.dotsandboxes.DefaultPlayer;
import clem.dotsandboxes.DotsAndBoxesUtils;
import clem.dotsandboxes.Edge;
import clem.dotsandboxes.Game;
import clem.dotsandboxes.GameState;
import clem.dotsandboxes.Player;

import org.junit.Test;

import com.google.common.collect.ImmutableList;

public class StupidRandomMoveDecisionEngineTest {

	@Test
	public void testFirstMoveFrom() {
		Player p = new DefaultPlayer("Youssef", new StupidRandomMoveDecisionEngine());
		GameState s = DefaultGameState.get(3, 3, ImmutableList.of(p));
		Game game = DefaultGame.INSTANCE;
		
		int iterations = 0;
		final int maxIterations = DotsAndBoxesUtils.gridEdgeCount(3, 3);
		while(!game.isGameCompleted(s)) {
			
			assertTrue(iterations < maxIterations);
			
			Edge e = StupidRandomMoveDecisionEngine.firstMoveFrom(s, 0, 0);
			s = s.withEdge(e, p);
			
			++iterations;			
		}
		
		assertTrue(game.isGameCompleted(s));
	}
	
}
