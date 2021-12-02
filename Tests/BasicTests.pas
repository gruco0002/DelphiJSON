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

    [Test]
    procedure BasicDeserializeTest;
  end;

implementation

uses DelphiJSON, DelphiJSONAttributes, System.JSON, JSONComparer;

const
  notSerText = 'not (de)serialized';

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

    createdThroughJSON: boolean;

    constructor Create;

    [DJConstructor]
    constructor CreateJSON;

  end;

procedure TBasicTests.Setup;
begin
end;

procedure TBasicTests.TearDown;
begin
end;

procedure TBasicTests.BasicDeserializeTest;
const
  res = '{"textField": "testText1", "boolField": true, "int": 123}';
var
  tmp: TTestClass;
begin

  tmp := DelphiJSON<TTestClass>.Deserialize(res);

  Assert.AreEqual('testText1', tmp.testText);
  Assert.AreEqual(true, tmp.testBool);
  Assert.AreEqual(123, tmp.testInt);
  Assert.AreEqual(notSerText, tmp.testTextNotSer);
  Assert.IsTrue(tmp.createdThroughJSON);

  tmp.Free;

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
  t.testBool := true;
  t.testInt := 123;
  Assert.IsFalse(t.createdThroughJSON);

  obj1 := DelphiJSON<TTestClass>.SerializeJ(t);
  ser := obj1.ToJSON;

  t.Free;

  obj2 := TJSONObject.ParseJSONValue(res, false, true);

  Assert.IsTrue(JSONEquals(obj1, obj2));

  obj1.Free;
  obj2.Free;

end;

{ TTestClass }

constructor TTestClass.Create;
begin
  createdThroughJSON := false;
  testTextNotSer := notSerText;
end;

constructor TTestClass.CreateJSON;
begin
  createdThroughJSON := true;
  testTextNotSer := notSerText;
end;

initialization

TDUnitX.RegisterTestFixture(TBasicTests);

end.
