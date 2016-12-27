package clem.dotsandboxes.prolog;

import clem.util.Pair;

public interface PrologRunner {
	
	public String excecute(String goal, String prologFilePath) 
		throws PrologException;
	
	public static class PrologException extends Exception {
		private static final long serialVersionUID = 1L;

		public PrologException() {
			super();
		}

		public PrologException(String message, Throwable cause) {
			super(message, cause);
		}

		public PrologException(String message) {
			super(message);
		}

		public PrologException(Throwable cause) {
			super(cause);
		}
		
	}
}
