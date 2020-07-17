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

    [Test]
    procedure TestBasicComparison;
  end;

implementation

uses
  JSONComparer, System.JSON;

procedure TJSONComparerTests.Setup;
begin
end;

procedure TJSONComparerTests.TearDown;
begin
end;

procedure TJSONComparerTests.TestBasicComparison;
var
  i, j, k: TJSONObject;
begin
  i := TJSONObject.Create;
  i.AddPair('test', TJSONNumber.Create(15));
  i.AddPair('test2', TJSONString.Create('Hello world'));

  j := TJSONObject.Create;
  j.AddPair('test2', TJSONString.Create('Hello world'));
  j.AddPair('test', TJSONNumber.Create(15));

  Assert.IsTrue(JSONEquals(i, j));
  Assert.IsTrue(JSONEquals(j, i));
  Assert.IsTrue(JSONEquals(i, i));
  Assert.IsTrue(JSONEquals(j, j));

  k := TJSONObject.Create;
  k.AddPair('test2', TJSONString.Create('Hello world'));
  k.AddPair('test123', TJSONNumber.Create(123));
  k.AddPair('test', TJSONNumber.Create(15));

  Assert.IsFalse(JSONEquals(k, i));
  Assert.IsFalse(JSONEquals(j, k));
  Assert.IsTrue(JSONEquals(k, k));

  i.Free;
  j.Free;
  k.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TJSONComparerTests);

end.
