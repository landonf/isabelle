/*
 * $Id$
 *
 * Simple demo for IsabelleProcess wrapper.
 *
 */

package isabelle;

public class IsabelleDemo extends IsabelleProcess {
    public IsabelleDemo(String logic) throws IsabelleProcessException
    {
        super(logic);
        new Thread (new Runnable () {
            public void run()
            {
                IsabelleProcess.Result result = null;
                while (result == null || result.kind != IsabelleProcess.Result.Kind.EXIT) {
                    try {
                        result = results.take();
                        System.err.println(result.toString());
                    } catch (InterruptedException ex) { }
                }
                System.err.println("Console thread terminated");
            }
        }).start();
    }
}
