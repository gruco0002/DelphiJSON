unit DefaultValueTests;

interface

uses
  DUnitX.TestFramework, DelphiJSON, System.Generics.Collections;

type

  [DJSerializable]
  TTestClass = class
  public

    [DJValue('str')]
    [DJRequired(false)]
    [DJDefaultValue('Hello World')]
    str: String;

    [DJValue('b')]
    [DJRequired(false)]
    [DJDefaultValue(true)]
    b: Boolean;

    [DJValue('i')]
    [DJRequired(false)]
    [DJDefaultValue(156)]
    i: Integer;

    [DJValue('s')]
    [DJRequired(false)]
    [DJDefaultValue(single(0.56))]
    s: single;

  end;

  TCustomListGenerator = class(DJDefaultValueCreatorAttribute < TList <
    String >> )
  public
    function Generator: TList<String>; override;
  end;

  [DJSerializable]
  TAnother = class
  public
    [DJValue('messages')]
    [DJRequired(false)]
    [TCustomListGenerator]
    messages: TList<String>;

  end;

  [TestFixture]
  TDefaultValueTests = class(TObject)
  public

    [Test]
    procedure Test1;

    [Test]
    procedure Test2;

    [Test]
    procedure TestGenerator;

    [Test]
    procedure TestGenerator2;

  end;

implementation

function Generator: TObject;
begin
  Result := TList<String>.Create();
  (Result as TList<String>).Add('Wow');
end;

{ TDefaultValueTests }

procedure TDefaultValueTests.Test1;
const
  res = '{}';
var
  tmp: TTestClass;
begin
  tmp := DelphiJSON<TTestClass>.Deserialize(res);

  Assert.AreEqual('Hello World', tmp.str);
  Assert.AreEqual(true, tmp.b);
  Assert.AreEqual(156, tmp.i);
  Assert.AreEqual(single(0.56), tmp.s);

  tmp.Free;
end;

procedure TDefaultValueTests.Test2;
const
  res = '{ "str": "Bye Bye!", "s": 123.123 }';
var
  tmp: TTestClass;
begin
  tmp := DelphiJSON<TTestClass>.Deserialize(res);

  Assert.AreEqual('Bye Bye!', tmp.str);
  Assert.AreEqual(true, tmp.b);
  Assert.AreEqual(156, tmp.i);
  Assert.AreEqual(single(123.123), tmp.s);

  tmp.Free;

end;

procedure TDefaultValueTests.TestGenerator;
const
  res = '{}';
var
  tmp: TAnother;
begin

  tmp := DelphiJSON<TAnother>.Deserialize(res);

  Assert.IsNotNull(tmp.messages);
  Assert.AreEqual(1, tmp.messages.Count);
  Assert.AreEqual('Yeah!', tmp.messages[0]);

  tmp.messages.Free;
  tmp.Free;

end;

procedure TDefaultValueTests.TestGenerator2;
const
  res = '{ "messages": ["abc", "def"] }';
var
  tmp: TAnother;
begin

  tmp := DelphiJSON<TAnother>.Deserialize(res);

  Assert.IsNotNull(tmp.messages);
  Assert.AreEqual(2, tmp.messages.Count);
  Assert.AreEqual('abc', tmp.messages[0]);
  Assert.AreEqual('def', tmp.messages[1]);

  tmp.messages.Free;
  tmp.Free;
end;

{ TEmptyListGenerator }

function TCustomListGenerator.Generator: TList<String>;
begin
  Result := TList<String>.Create;
  Result.Add('Yeah!');
end;

initialization

TDUnitX.RegisterTestFixture(TDefaultValueTests);

end.
