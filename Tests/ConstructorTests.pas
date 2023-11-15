unit ConstructorTests;

interface

uses
  DUnitX.TestFramework, DelphiJSON;

type

  [DJSerializable]
  TConstr1 = class
  public

    [DJValue('data')]
    data: String;

    constructor Create;

    [DJConstructor]
    constructor FromJSON;
  end;

  [DJSerializable]
  TConstr2 = class
  public

    [DJValue('data')]
    data: String;

    [DJConstructor]
    constructor Create;

    constructor FromJSON;
  end;

  [DJSerializable]
  TConstr3 = class
  public

    [DJValue('data')]
    data: String;

    constructor Create;

    constructor FromJSON;
  end;

  [TestFixture]
  TConstructorTests = class(TObject)
  public

    [Test]
    procedure TestAnnotatedConstructor1;

    [Test]
    procedure TestAnnotatedConstructor2;

    [Test]
    procedure TestDefaultConstructor;

  end;

implementation


{TConstr1}

constructor TConstr1.Create;
begin
  Assert.Fail();
end;

constructor TConstr1.FromJSON;
begin
  // Assert.Pass();
end;

{TConstructorTests}

procedure TConstructorTests.TestAnnotatedConstructor1;
const
  res = '{ "data": "hello world" }';
var
  tmp: TConstr1;
begin
  tmp := DelphiJSON<TConstr1>.Deserialize(res);

  tmp.Free;

end;

procedure TConstructorTests.TestAnnotatedConstructor2;
const
  res = '{ "data": "hello world" }';
var
  tmp: TConstr2;
begin
  tmp := DelphiJSON<TConstr2>.Deserialize(res);

  tmp.Free;
end;

procedure TConstructorTests.TestDefaultConstructor;
const
  res = '{ "data": "hello world" }';
var
  tmp: TConstr3;
begin
  tmp := DelphiJSON<TConstr3>.Deserialize(res);

  tmp.Free;

end;

{TConstr2}

constructor TConstr2.Create;
begin
  // Assert.Pass();
end;

constructor TConstr2.FromJSON;
begin
  Assert.Fail();
end;

{TConstr3}

constructor TConstr3.Create;
begin
  // Assert.Pass();
end;

constructor TConstr3.FromJSON;
begin
  Assert.Fail();
end;

initialization

TDUnitX.RegisterTestFixture(TConstructorTests);

end.
