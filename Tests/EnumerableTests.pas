unit EnumerableTests;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TEnumerableTests = class(TObject) 
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  end;

implementation

procedure TEnumerableTests.Setup;
begin
end;

procedure TEnumerableTests.TearDown;
begin
end;


initialization
  TDUnitX.RegisterTestFixture(TEnumerableTests);
end.
