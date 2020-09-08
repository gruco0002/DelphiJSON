unit ArrayTests;

interface

uses
  DUnitX.TestFramework, DelphiJSON;

type

  [TestFixture]
  TArrayTests = class(TObject)
  public

    [Test]
    procedure TestSerDynArr;
    [Test]
    procedure TestDerDynArr;
    [Test]
    procedure TestSerFixedArr;
    [Test]
    procedure TestDerFixedArr;

  end;

  TFixedArray = array [0 .. 2] of string;

implementation

uses
  System.JSON, JSONComparer;

{ TArrayTests }

procedure TArrayTests.TestDerDynArr;
const
  res = '["Hello", "World", "!"]';
var
  arr: TArray<String>;
begin

  arr := DelphiJSON < TArray < String >>.Deserialize(res);

  Assert.AreEqual(3, Length(arr));
  Assert.AreEqual('Hello', arr[0]);
  Assert.AreEqual('World', arr[1]);
  Assert.AreEqual('!', arr[2]);

  SetLength(arr, 1);
  Assert.AreEqual(1, Length(arr));
  Assert.AreEqual('Hello', arr[0]);

end;

procedure TArrayTests.TestDerFixedArr;
const
  res = '["Hello", "World", "!"]';
  res2 = '["Hello", "World"]';
var
  arr: TFixedArray;
begin

  arr := DelphiJSON<TFixedArray>.Deserialize(res);

  Assert.AreEqual(3, Length(arr));
  Assert.AreEqual('Hello', arr[0]);
  Assert.AreEqual('World', arr[1]);
  Assert.AreEqual('!', arr[2]);

  arr[2] := 'wuuu';

  Assert.WillRaise(
    procedure
    begin
      arr := DelphiJSON<TFixedArray>.Deserialize(res2);
    end, EDJWrongArraySizeError);
end;

procedure TArrayTests.TestSerDynArr;
var
  desired: TJSONArray;
  serialized: TJSONValue;
  val: TArray<String>;
begin

  desired := TJSONArray.Create;
  desired.Add('Hello');
  desired.Add('World');
  desired.Add('!');

  SetLength(val, 3);
  val[0] := 'Hello';
  val[1] := 'World';
  val[2] := '!';

  serialized := DelphiJSON < TArray < String >>.SerializeJ(val);

  Assert.IsTrue(JSONEquals(desired, serialized));

  serialized.Free;
  desired.Free;

end;

procedure TArrayTests.TestSerFixedArr;
var
  desired: TJSONArray;
  serialized: TJSONValue;
  val: TFixedArray;
begin

  desired := TJSONArray.Create;
  desired.Add('Hello');
  desired.Add('World');
  desired.Add('!');

  val[0] := 'Hello';
  val[1] := 'World';
  val[2] := '!';

  serialized := DelphiJSON<TFixedArray>.SerializeJ(val);

  Assert.IsTrue(JSONEquals(desired, serialized));

  serialized.Free;
  desired.Free;
end;

initialization

TDUnitX.RegisterTestFixture(TArrayTests);

end.
