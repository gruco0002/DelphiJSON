unit CycleTests;

interface

uses
  DUnitX.TestFramework, DelphiJSONAttributes;

type

  [DJSerializable]
  TCycle = class

  public

    [DJValue('value')]
    value: string;

    [DJValue('ref')]
    ref: TCycle;

  end;

  [TestFixture]
  TCycleTests = class(TObject)
  public

    [Test]
    procedure TestCycle;

    [Test]
    procedure TestNoCycle;

  end;

implementation

uses
  DelphiJSON, DelphiJSONTypes;

{ TCycleTests }

procedure TCycleTests.TestCycle;
var
  tmp1: TCycle;
  tmp2: TCycle;
  tmp: string;
begin
  tmp1 := TCycle.Create;
  tmp1.value := 'Hello';
  tmp2 := TCycle.Create;
  tmp2.value := 'World';

  tmp1.ref := tmp1;
  tmp2.ref := tmp1;

  Assert.WillRaise(
    procedure
    begin
      tmp := DelphiJSON<TCycle>.Serialize(tmp1);
    end, EDJCycleError);

  Assert.WillRaise(
    procedure
    begin
      tmp := DelphiJSON<TCycle>.Serialize(tmp2);
    end, EDJCycleError);

  tmp1.ref := tmp2;

  Assert.WillRaise(
    procedure
    begin
      tmp := DelphiJSON<TCycle>.Serialize(tmp1);
    end, EDJCycleError);

  Assert.WillRaise(
    procedure
    begin
      tmp := DelphiJSON<TCycle>.Serialize(tmp2);
    end, EDJCycleError);

  tmp1.Free;
  tmp2.Free;

end;

procedure TCycleTests.TestNoCycle;
var
  tmp1: TCycle;
  tmp2: TCycle;
  tmp: string;
begin
  tmp1 := TCycle.Create;
  tmp1.value := 'Hello';
  tmp2 := TCycle.Create;
  tmp2.value := 'World';

  tmp1.ref := tmp2;
  tmp2.ref := nil;

  Assert.WillNotRaise(
    procedure
    begin
      tmp := DelphiJSON<TCycle>.Serialize(tmp1);
    end, EDJCycleError);

  Assert.WillNotRaise(
    procedure
    begin
      tmp := DelphiJSON<TCycle>.Serialize(tmp2);
    end, EDJCycleError);

  tmp2.ref := tmp1;
  tmp1.ref := nil;

  Assert.WillNotRaise(
    procedure
    begin
      tmp := DelphiJSON<TCycle>.Serialize(tmp1);
    end, EDJCycleError);

  Assert.WillNotRaise(
    procedure
    begin
      tmp := DelphiJSON<TCycle>.Serialize(tmp2);
    end, EDJCycleError);

  tmp1.Free;
  tmp2.Free;

end;

initialization

TDUnitX.RegisterTestFixture(TCycleTests);

end.
