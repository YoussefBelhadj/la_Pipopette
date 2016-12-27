package clem.dotsandboxes.textinterface;

import clem.dotsandboxes.DefaultPlayer;
import clem.dotsandboxes.Player;
import clem.dotsandboxes.decision.DecisionEngine;
import clem.dotsandboxes.decision.JavaMinimaxDecisionEngine;
import clem.dotsandboxes.decision.JavaMinimaxDecisionEngine.MinimaxType;
import clem.dotsandboxes.decision.PrologDecisionEngine;
import clem.dotsandboxes.decision.StupidRandomMoveDecisionEngine;
import clem.dotsandboxes.decision.UserInputDecisionEngine;
import clem.dotsandboxes.prolog.PrologRunner;
import clem.dotsandboxes.prolog.SicstusPrologRunner;
import clem.dotsandboxes.prolog.SwiPrologRunner;
import clem.dotsandboxes.prolog.Utils;

import java.io.File;
import java.io.IOException;

import org.apache.commons.lang.SystemUtils;

import com.google.common.collect.ImmutableList;

public final class Players {
	private Players() { throw new AssertionError(); }
	
	public static ImmutableList<Player> makePlayers(Options options) 
			throws IOException {
		
		PrologRunner plRunner = null;
		File plFile = null;
		if(options.playerOneType() == PlayerType.prolog || 
				options.playerTwoType() == PlayerType.prolog) {
			
			// Extract the prolog source to a temp file...
			plFile = Utils.extractResourceToTempFile(
					Utils.DOTS_AND_BOXES_PROLOG_FILE);
			
			File prologExecutable;
			if(options.getPrologPath().contains(SystemUtils.FILE_SEPARATOR))
				prologExecutable = new File(options.getPrologPath());
			else {
				prologExecutable = Utils.findProgramOnPath(
						options.getPrologPath());
				if(prologExecutable == null) {
					System.err.println(
							"Could not find program in the search path: " + 
							options.getPrologPath());
					System.exit(1);
				}
					
			}
			
			if(options.getPrologType() == PrologEngine.sicstus)
				plRunner = new SicstusPrologRunner(prologExecutable);
			else
				plRunner = new SwiPrologRunner(prologExecutable);
		}
		
		return ImmutableList.of(
				makePlayerOne(options, plRunner, plFile),
				makePlayerTwo(options, plRunner, plFile));
	}
	
	public static Player makePlayerOne(Options options, PrologRunner plRunner,
			File plFile) {
		return makePlayer(options.playerOneName(), options.playerOneType(), 
				options.getP1Lookahead(), plRunner, plFile);
	}
	
	public static Player makePlayerTwo(Options options, PrologRunner plRunner,
			File plFile) {
		return makePlayer(options.playerTwoName(), options.playerTwoType(), 
				options.getP2Lookahead(), plRunner, plFile);
	}
	
	public static Player makePlayer(String name, PlayerType controllerType, 
			int lookahead, PrologRunner plRunner, File plFile) {
		
		DecisionEngine de;
		switch(controllerType) {
			case java:
				de = new JavaMinimaxDecisionEngine(
						lookahead, MinimaxType.NORMAL_MINIMAX);
				break;
			case human:
				de = new UserInputDecisionEngine(System.out, System.in);
				break;
			case prolog:
				de = new PrologDecisionEngine(lookahead, plRunner, plFile);
				break;
			case stupid:
				de = new StupidRandomMoveDecisionEngine();
				break;
			default:
				throw new AssertionError();
		}
		
		return new DefaultPlayer(name, de);
	}
}
