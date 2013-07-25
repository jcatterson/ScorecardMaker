public class ScorecardDriver
{
	public Scorecard card { get; private set; }
	public Scorecard originalCard { get; private set; }
	public ScorecardDriver()
	{
		card = new Scorecard('a00i0000001LkJS');
		originalCard = new Scorecard('a00i0000001Ln1N');
	}
}