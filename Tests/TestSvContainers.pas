﻿(*
* Copyright (c) 2012, Linas Naginionis
* Contacts: lnaginionis@gmail.com or support@soundvibe.net
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the <organization> nor the
*       names of its contributors may be used to endorse or promote products
*       derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)
unit TestSvContainers;

interface

uses
  TestFramework, SysUtils, Classes, SvContainers, Diagnostics, SvCollections.Tries;

type
  TestRec = record
    Name: string;
    ID: Integer;
  end;

  TestObj = class
  public
    Name: string;
    ID: Integer;
  end;

  TestTSvStringTrie = class(TTestCase)
  private
    FTrie: TSvStringTrie<TestRec>;
    sw: TStopwatch;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAdd();
    procedure TestDelete();
    procedure TestFind();
    procedure TestEnumerator();
    procedure TestIterateOver();
    procedure TestStatistics();
    procedure TestTryGetValues();
  end;

  TestTSvTrieDictionary = class(TTestCase)
  private
    FTrie: TSvTrie<string,TestObj>;
    sw: TStopwatch;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAdd();
  end;

implementation

uses
  Generics.Collections;

{ TestTSvStringTrie }

{$HINTS OFF}
{$WARNINGS OFF}

procedure TestTSvStringTrie.SetUp;
begin
  inherited;
  FTrie := TSvStringTrie<TestRec>.Create;
end;

procedure TestTSvStringTrie.TearDown;
begin
  FTrie.Free;
  inherited;
end;

const
  ITER_SIZE = 100000;

procedure TestTSvStringTrie.TestAdd;
var
  rec: TestRec;
  i: Integer;
begin
  FTrie.Clear;
  sw := TStopwatch.StartNew;
  for i := 1 to ITER_SIZE do
  begin
    rec.ID := i;
    rec.Name := IntToStr(i);

    FTrie.Add(rec.Name, rec);
  end;
  sw.Stop;

  CheckEquals(ITER_SIZE, FTrie.Count);

  Status(Format('%D items added in %D ms', [FTrie.Count, sw.ElapsedMilliseconds]));
end;

procedure TestTSvStringTrie.TestDelete;
var
  i: Integer;
begin
  TestAdd;

  sw := TStopwatch.StartNew;
  for i := 1 to ITER_SIZE do
  begin
    FTrie.Delete(IntToStr(i));
  end;
  sw.Stop;

  CheckEquals(0, FTrie.Count);
  Status(Format('%D items deleted in %D ms', [FTrie.Count, sw.ElapsedMilliseconds]));
end;

procedure TestTSvStringTrie.TestEnumerator;
var
  ix: Integer;
  pair: TPair<string,TestRec>;
  dict: TDictionary<Integer, Boolean>;
begin
  TestAdd;
  ix := 0;
  dict := TDictionary<Integer, Boolean>.Create(FTrie.Count);
  try
    for pair in FTrie do
    begin
      CheckFalse(dict.ContainsKey(pair.Value.ID), Format('Duplicated key on iteration %D',[ix]));
      dict.Add(pair.Value.ID, True);

      Inc(ix);
    end;

    CheckEquals(ix, ITER_SIZE);
  finally
    dict.Free;
  end;
end;

procedure TestTSvStringTrie.TestFind;
var
  rec: TestRec;
  i: Integer;
begin
  TestAdd;
  sw := TStopwatch.StartNew;
  for i := 1 to ITER_SIZE do
  begin
    rec.ID := -1;
    rec.Name := '';
    CheckTrue( FTrie.TryGetValue(IntToStr(i), rec));
    CheckEquals(i, rec.ID);
    CheckEqualsString(IntToStr(i), rec.Name);
  end;
  sw.Stop;

  Status(Format('%D items found in %D ms', [FTrie.Count, sw.ElapsedMilliseconds]));

  CheckFalse(FTrie.TryGetValue('random valuesdsd', rec));
end;

procedure TestTSvStringTrie.TestIterateOver;
var
  ix: Integer;
  dict: TDictionary<Integer, Boolean>;
begin
  TestAdd;
  ix := 0;


  dict := TDictionary<Integer, Boolean>.Create(FTrie.Count);
  try
    FTrie.IterateOver(
      procedure(const AKey: string; const AData: TestRec; var Abort: Boolean)
      begin
        CheckFalse(dict.ContainsKey(AData.ID), Format('Duplicated key on iteration %D',[ix]));
        dict.Add(AData.ID, True);

        Inc(ix);
      end);

    CheckEquals(FTrie.Count, ix);

    ix := 0;
    FTrie.IterateOver(
      procedure(const AKey: string; const AData: TestRec; var Abort: Boolean)
      begin
        Inc(ix);
        Abort := ( ix = 100);
      end);

    CheckEquals(100, ix);

  finally
    dict.Free;
  end;
end;



procedure TestTSvStringTrie.TestStatistics;
var
  maxlev,pCount,fCount,eCount: Integer;
  lStat: TLengthStatistics;
begin
  TestAdd;

  FTrie.TrieStatistics(maxlev, pCount, fCount, eCount, lStat);

  CheckTrue(maxlev > 0);
end;

const
  ARRTEXT: array[0..9] of string =
    ('First',
     'First Text',
     'Was first place',
     'first try',
     'first and second versions were awesome',
     'some demo quote',
     'he was old',
     'he is old',
     'he',
     'she is young');

procedure TestTSvStringTrie.TestTryGetValues;
var
  i: Integer;
  rec: TestRec;
  results: TList<TestRec>;
begin
  //add some text
  for i := Low(ARRTEXT) to high(ARRTEXT) do
  begin
    rec.ID := i;
    rec.Name := ARRTEXT[i];
    FTrie.Add(ARRTEXT[i], rec);
  end;

  CheckEquals(Length(ARRTEXT), FTrie.Count);

  if FTrie.TryGetValues('First', results) then
  begin
    try
      CheckEquals(4, results.Count);
    finally
      results.Free;
    end;
  end;
end;

{$HINTS ON}
{$WARNINGS ON}

{ TestTSvTrieDictionary }

procedure TestTSvTrieDictionary.SetUp;
begin
  inherited;
  FTrie := TSvTrie<string,TestObj>.Create();
end;

procedure TestTSvTrieDictionary.TearDown;
begin
  FTrie.Free;
  inherited;
end;

procedure TestTSvTrieDictionary.TestAdd;
var
//  rec: TestRec;
  i: Integer;
  obj: TestObj;
begin
  FTrie.Clear;
  sw := TStopwatch.StartNew;
  for i := 1 to ITER_SIZE do
  begin
    //rec.ID := i;
   // rec.Name := IntToStr(i);
    obj := TestObj.Create;
    obj.Name := 'Name ' + IntToStr(i);
    obj.ID := i;
    FTrie.Add(obj.Name, obj);
  end;
  sw.Stop;

  CheckEquals(ITER_SIZE, FTrie.Count);

  Status(Format('%D items added in %D ms', [FTrie.Count, sw.ElapsedMilliseconds]));
end;

initialization
  RegisterTest(TestTSvStringTrie.Suite);
  RegisterTest(TestTSvTrieDictionary.Suite);

end.
