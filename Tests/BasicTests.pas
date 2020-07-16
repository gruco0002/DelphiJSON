unit BasicTests;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TBasicTests = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    procedure Test1;
    // Test with TestCase Attribute to supply parameters.
    [Test]
    [TestCase('TestA', '1,2')]
    [TestCase('TestB', '1,1')]
    procedure Test2(const AValue1: Integer; const AValue2: Integer);
  end;

implementation

procedure TBasicTests.Setup;
begin
end;

procedure TBasicTests.TearDown;
begin
end;

procedure TBasicTests.Test1;
begin
  Assert.IsTrue(True);
end;

procedure TBasicTests.Test2(const AValue1: Integer; const AValue2: Integer);
begin
  Assert.AreEqual(AValue1, AValue2);
end;

initialization

TDUnitX.RegisterTestFixture(TBasicTests);

end.
