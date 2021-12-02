unit RecordArrayTests;

interface

uses
  DUnitX.TestFramework, DelphiJSONAttributes;

type

  [TestFixture]
  TRecordArrayTests = class
  public

    [Test]
    procedure TestRecordDynArraySer;

    [Test]
    procedure TestRecordDynArrayDer;

  end;

  [DJSerializable]
  TRecordDynArrayTestRecord = record
  public
    [DJValue('arr')]
    arr: TArray<string>;
  end;

implementation

uses
  System.JSON, JSONComparer, DelphiJSON;

{ TRecordArrayTests }

procedure TRecordArrayTests.TestRecordDynArrayDer;
const
  data = '{"arr":["a", "b", "c", "abc"]}';
var
  deserialized: TRecordDynArrayTestRecord;
begin
  deserialized := DelphiJSON<TRecordDynArrayTestRecord>.Deserialize(data);
  Assert.AreEqual(4, Length(deserialized.arr));
  Assert.AreEqual('a', deserialized.arr[Low(deserialized.arr) + 0]);
  Assert.AreEqual('b', deserialized.arr[Low(deserialized.arr) + 1]);
  Assert.AreEqual('c', deserialized.arr[Low(deserialized.arr) + 2]);
  Assert.AreEqual('abc', deserialized.arr[Low(deserialized.arr) + 3]);
end;

procedure TRecordArrayTests.TestRecordDynArraySer;
const
  expectedJSON = '{"arr":["hello", "world", "abc"]}';
var
  toSerialize: TRecordDynArrayTestRecord;
  serialized: TJSONValue;
  expected: TJSONValue;
begin
  // create data that should be serialized
  SetLength(toSerialize.arr, 3);
  toSerialize.arr[Low(toSerialize.arr) + 0] := 'hello';
  toSerialize.arr[Low(toSerialize.arr) + 1] := 'world';
  toSerialize.arr[Low(toSerialize.arr) + 2] := 'abc';

  // serialize
  serialized := DelphiJSON<TRecordDynArrayTestRecord>.SerializeJ(toSerialize);

  // create expected json value
  expected := TJSONObject.ParseJSONValue(expectedJSON);

  // compare
  Assert.IsTrue(JSONComparer.JSONEquals(expected, serialized));

  // cleanup
  expected.Free;
  serialized.Free;

end;

initialization

TDUnitX.RegisterTestFixture(TRecordArrayTests);

end.
