include "number.dfy"
include "maps.dfy"
include "tx.dfy"



// Fixed point arithmetic math
// https://github.com/dapphub/ds-math/blob/master/src/math.sol
module Fixed {

import opened Number
import opened Maps
import opened Tx

    // const WAD: u256 := 1_000_000_000_000_000_000 // 18 zeros
    const WAD: u256 := 1_000
    const RAY: u256 := 1_000_000_000_000_000_000_000_000_000 // 27

    function Add(x: u256, y: u256) : u256 
    requires (x as nat) + (y as nat) <= MAX_U256 as nat{
        x + y
    }

    function Sub(x: u256, y: u256) : u256
    requires (x as nat) - (y as nat) >= 0 as nat {
        x - y
    }

    function Div(x: u256, y: u256) : u256
    requires (y as nat) > 0 as nat {
        x / y
    }

    function Mul(x: u256, y: u256) : u256
    requires (x as nat) * (y as nat) <= MAX_U256 as nat {
        x * y
    }

    function Wmul(x: u256, y: u256) : u256 
    requires y == 0 || (x as nat) * (y as nat) <= MAX_U256 as nat 
    requires Mul(x,y) as nat <= MAX_U256 {
        var m: u256 := Mul(x,y);
        var w: u256 := WAD / 2;
        assume {:axiom} (m as nat) + (w as nat) <= MAX_U256 as nat;
        (Add(m , w))/WAD
    }

    function Wmul2(x: nat, y: nat) : nat {
        var w := 1000000000000000000;
        ((x * y) + (w / 2)) / w
    }

    function Wdiv(x: u256, y: u256) : (r: u256)
    requires (x as nat) * (y as nat) <= MAX_U256 as nat
    requires (x as nat) * (WAD as nat) <= MAX_U256 as nat
    requires Mul(x, WAD) as nat + (y / 2) as nat <= MAX_U256
    requires y != 0
    ensures r < MAX_U256 as u256 {
        var m: u256 := Mul(x, WAD);
        var w: u256 := y / 2;
        var z: u256 := Add(m, w);
        z / y
    }
}

// --- TESTS

import opened Fixed
import opened Number
import opened Maps
import opened Tx

method {:test} testFindMax() {
    var j := 1000000000000000000 as u256;
    var i := 1000000000000000000 as u256;
    var r := 1000000000000000000 as u256;

    var a := 2000 as u256;
    var b := 4000 as u256;

    assert Wdiv(a, b) == 500;

    // assert Wmul(j,i) == r; 
    assert Wmul(WAD, WAD) == WAD;

    var x : nat := 100000000000000000;
    
    // 10^18 * 10^18 = 10^36
    //print(x*x); // it has 34 zeros ! help

    var x1 : nat := 1000000000000000000;
    var x2 : nat := 1000000000000000000;
    var r1 : nat := 1000000000000000000000000000000000000;
    var r2 : nat := (r1 + (x1/2)) / x1;
    assert x1*x2 == r1;
    assert Wmul2(x1, x2) == 1000000000000000000; // 18 zeros

    print(x1*x2);
    assert r2 == x1;
}









