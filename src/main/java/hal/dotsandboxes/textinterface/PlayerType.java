package hal.dotsandboxes.textinterface;

import hal.dotsandboxes.DefaultGame;
import hal.dotsandboxes.decision.DecisionEngine;
import hal.dotsandboxes.decision.JavaMinimaxDecisionEngine;
import hal.dotsandboxes.decision.PrologDecisionEngine;
import hal.dotsandboxes.decision.StupidRandomMoveDecisionEngine;
import hal.dotsandboxes.decision.UserInputDecisionEngine;

/**
 * Enumerates the supported methods of making game play decisions.
 * 
 * <p>Note that lower case names are used for user friendliness as the names are
 * used directly by the command line argument parser.
 * 
 * @author Hal Blackburn
 */
public enum PlayerType {
	
	human, 
	prolog, 
	stupid, 
	java;
}
