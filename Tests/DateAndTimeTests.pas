unit DateAndTimeTests;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TDateAndTimeTests = class(TObject) 
  public
  end;

implementation


initialization
  TDUnitX.RegisterTestFixture(TDateAndTimeTests);
end.
