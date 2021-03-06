package clem.dotsandboxes.prolog;

import clem.util.Pair;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.apache.commons.exec.CommandLine;
import org.apache.commons.exec.DefaultExecutor;
import org.apache.commons.exec.ExecuteException;
import org.apache.commons.exec.PumpStreamHandler;
import org.apache.commons.lang.StringUtils;

import static com.google.common.base.Preconditions.*;

public abstract class AbstractExternalProcessPrologRunner 
	implements PrologRunner {

	private final File mExecutable;
	
	protected AbstractExternalProcessPrologRunner(File executable) {
		mExecutable = checkNotNull(executable);
	}
	
	@Override
	public String excecute(String goal, String prologFilePath) 
		throws PrologException {
		
		DefaultExecutor exec = new DefaultExecutor();
		
		String cmd = String.format("\"%s\" %s",
				mExecutable.getAbsolutePath(),
				getArguments(goal, prologFilePath));
		
		CommandLine cmdLine = CommandLine.parse(cmd);		
		
		ByteArrayOutputStream stdout = new ByteArrayOutputStream();
		ByteArrayOutputStream stderr = new ByteArrayOutputStream();
		
		exec.setStreamHandler(new PumpStreamHandler(stdout, stderr));
		try {
			exec.execute(cmdLine);
		} 
		catch (ExecuteException e) {
			throw new PrologException("Error running prolog process:\n" + 
					stderr.toString(),
					e);
		}
		catch (IOException e) {
			throw new PrologException("IO Error occoured when running process.",
					e);
		}
		
		return stdout.toString();
	}
	
	protected abstract String getArguments(String goal, String prologFilePath);
}
