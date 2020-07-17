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

  obj1.Free;
  obj2.Free;

end;

initialization

TDUnitX.RegisterTestFixture(TBasicTests);

end.
