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

    [Test]
    procedure TestListSerialization;

    [Test]
    procedure TestDictSerialization;

    [Test]
    procedure TestListDeserialization;

  end;

implementation

uses
  JSONComparer, DelphiJSON, System.JSON, System.Generics.Collections;

type

  [DJSerializable]
  TTest = class

  [DJValue('field')]
    field: integer;

    [DJValue('intList')]
    list: TList<integer>;

  end;

  [DJSerializable]
  TTest2 = class

  [DJValue('field')]
    field: integer;

    [DJValue('data')]
    data: TDictionary<integer, string>;

  end;

procedure TEnumerableTests.Setup;
begin
end;

procedure TEnumerableTests.TearDown;
begin
end;

procedure TEnumerableTests.TestDictSerialization;
const
  res = '{"field":123, "data":[{"key":5, "value":"five"}, {"key":3, "value":"three"}, {"key":2, "value":"two"}, {"key":7, "value":"seven"}, {"key":11, "value":"eleven"}]}';
var
  tmp: TTest2;
  desired: TJSONValue;
  ser: TJSONValue;
  s: string;
begin

  tmp := TTest2.Create;
  tmp.field := 123;
  tmp.data := TDictionary<integer, string>.Create;

  tmp.data.Add(5, 'five');
  tmp.data.Add(3, 'three');
  tmp.data.Add(2, 'two');
  tmp.data.Add(7, 'seven');
  tmp.data.Add(11, 'eleven');

  ser := DelphiJSON<TTest2>.SerializeJ(tmp);

  s := ser.ToJSON;

  tmp.data.Free;
  tmp.Free;

  desired := TJSONObject.ParseJSONValue(res, false, True);

  Assert.IsTrue(JSONEquals(ser, desired, false));

  desired.Free;
  ser.Free;

end;

procedure TEnumerableTests.TestListDeserialization;
const
  res = '{"field":123, "intList":[12, 13, 42]}';
var
  Test: TTest;
begin

  Test := DelphiJSON<TTest>.Deserialize(res);

  Assert.AreEqual(123, Test.field);

  Assert.AreEqual(3, Test.list.Count);
  Assert.AreEqual(12, Test.list[0]);
  Assert.AreEqual(13, Test.list[1]);
  Assert.AreEqual(42, Test.list[2]);

  Test.list.Free;
  Test.Free;
end;

procedure TEnumerableTests.TestListSerialization;
const
  res = '{"field":123, "intList":[12, 13, 42]}';
var
  tmp: TTest;
  ser: TJSONValue;
  desired: TJSONValue;
  s: string;
begin

  desired := TJSONObject.ParseJSONValue(res, false, True);

  tmp := TTest.Create;
  tmp.field := 123;
  tmp.list := TList<integer>.Create;
  tmp.list.Add(12);
  tmp.list.Add(13);
  tmp.list.Add(42);

  ser := DelphiJSON<TTest>.SerializeJ(tmp);

  s := ser.ToJSON;

  tmp.list.Free;
  tmp.Free;

  Assert.IsTrue(JSONEquals(ser, desired));

  desired.Free;
  ser.Free;

end;

initialization

TDUnitX.RegisterTestFixture(TEnumerableTests);

end.
