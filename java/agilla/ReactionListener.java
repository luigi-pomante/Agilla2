/**
 * ReactionListener.java
 *
 * @author Chien-Liang Fok
 */

package agilla;

public interface ReactionListener
{
	/**
	 * This method is called when a reaction fires.
	 *
	 * @param t The tuple that caused the reaction to fire.
	 */
	public void reactionFired(Tuple t);
}

