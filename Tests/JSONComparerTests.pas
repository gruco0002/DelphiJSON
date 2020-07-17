unit JSONComparerTests;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TJSONComparerTests = class(TObject) 
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  end;

implementation

procedure TJSONComparerTests.Setup;
begin
end;

procedure TJSONComparerTests.TearDown;
begin
end;


initialization
  TDUnitX.RegisterTestFixture(TJSONComparerTests);
end.
