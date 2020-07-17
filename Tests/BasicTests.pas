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

    [Test]
    procedure SystemJSONComparison;

    [Test]
    procedure BasicSerializeTest;
  end;

implementation

uses DelphiJSON, System.JSON, JSONComparer;

type

  [DJSerializable]
  TTestClass = class(TObject)

    [DJValue('textField')]
    testText: string;

    testTextNotSer: string;

    [DJValue('boolField')]
    testBool: boolean;

    [DJValue('int')]
    testInt: Integer;

  end;

procedure TBasicTests.Setup;
begin
end;

procedure TBasicTests.TearDown;
begin
end;

procedure TBasicTests.SystemJSONComparison;
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

procedure TBasicTests.BasicSerializeTest;
const
  res = '{"textField": "testText1", "boolField": true, "int": 123}';
var
  t: TTestClass;
  ser: string;

  obj1: TJSONValue;
  obj2: TJSONValue;
begin

  t := TTestClass.Create;
  t.testText := 'testText1';
  t.testTextNotSer := 'do not serialize';
  t.testBool := True;
  t.testInt := 123;

  obj1 := DelphiJSON<TTestClass>.SerializeJ(t);
  ser := obj1.ToJSON;

  t.Free;

  obj2 := TJSONObject.ParseJSONValue(res, false, True);

  Assert.IsTrue(JSONEquals(obj1, obj2));

end;

initialization

TDUnitX.RegisterTestFixture(TBasicTests);

end.
