package clem.dotsandboxes;

import clem.dotsandboxes.decision.DecisionEngine;

import static com.google.common.base.Preconditions.*;

public class DefaultPlayer implements Player {

	private final String mName;
	
	private final DecisionEngine mDecisionEngine;
	
	public DefaultPlayer(String name, DecisionEngine decisionEngine) {
		checkNotNull(name);
		checkArgument(!name.isEmpty(), "name cannot be empty");
		checkNotNull(decisionEngine);
		
		mName = name;
		mDecisionEngine = decisionEngine;
	}
	
	@Override
	public String getName() {
		return mName;
	}

	@Override
	public DecisionEngine getDecisionEngine() {
		return mDecisionEngine;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result
				+ ((mDecisionEngine == null) ? 0 : mDecisionEngine.hashCode());
		result = prime * result + ((mName == null) ? 0 : mName.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		DefaultPlayer other = (DefaultPlayer) obj;
		if (mDecisionEngine == null) {
			if (other.mDecisionEngine != null)
				return false;
		} else if (!mDecisionEngine.equals(other.mDecisionEngine))
			return false;
		if (mName == null) {
			if (other.mName != null)
				return false;
		} else if (!mName.equals(other.mName))
			return false;
		return true;
	}
	
	@Override
	public String toString() {
		return String.format("Player(name: %s, decisionEngine: %s)", mName, 
				mDecisionEngine);
	}
}
