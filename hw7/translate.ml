open Mach
open Mono 

exception NotImplemented
exception OperatorError

(* location *)
type loc =
    L_INT of int          (* integer constant *)
  | L_BOOL of bool        (* boolean constant *)
  | L_UNIT                (* unit constant *)
  | L_STR of string       (* string constant *)
  | L_ADDR of Mach.addr   (* at the specified address *)
  | L_REG of Mach.reg     (* at the specified register *)
  | L_DREF of loc * int   (* at the specified location with the specified offset *)

type venv = (Mono.avid, loc) Dict.dict  (* variable environment *)
let venv0 : venv = Dict.empty           (* empty variable environment *)

type env = venv * int
let env0 : env = (venv0, 0)

let regcount = ref 0;

let allocate_memory = if (!regcount < 20) then (regcount := (!regcount + 1)) else ()

let free_memory = 

(* val loc2rvalue : loc -> Mach.code * rvalue *)
let rec loc2rvalue l = match l with
    L_INT i -> (Mach.code0, Mach.INT i)
  | L_BOOL b -> (Mach.code0, Mach.BOOL b)
  | L_UNIT -> (Mach.code0, Mach.UNIT)
  | L_STR s -> (Mach.code0, Mach.STR s)
  | L_ADDR a -> (Mach.code0, Mach.ADDR a)
  | L_REG r -> (Mach.code0, Mach.REG r)
  | L_DREF (L_ADDR a, i) -> (Mach.code0, Mach.REFADDR (a, i))
  | L_DREF (L_REG r, i) -> (Mach.code0, Mach.REFREG (r, i))
  | L_DREF (l, i) ->
     let (code, rvalue) = loc2rvalue l in
     (Mach.cpost code [Mach.MOVE (Mach.LREG Mach.tr, rvalue)], Mach.REFREG (Mach.tr, i))

(*
 * helper functions for debugging
 *)
(* val loc2str : loc -> string *)
let rec loc2str l = match l with 
    L_INT i -> "INT " ^ (string_of_int i)
  | L_BOOL b -> "BOOL " ^ (string_of_bool b)
  | L_UNIT -> "UNIT"
  | L_STR s -> "STR " ^ s
  | L_ADDR (Mach.CADDR a) -> "ADDR " ^ ("&" ^ a)
  | L_ADDR (Mach.HADDR a) -> "ADDR " ^ ("&Heap_" ^ (string_of_int a))
  | L_ADDR (Mach.SADDR a) -> "ADDR " ^ ("&Stack_" ^ (string_of_int a))
  | L_REG r -> 
     if r = Mach.sp then "REG SP"
     else if r = Mach.bp then "REG BP"
     else if r = Mach.cp then "REG CP"
     else if r = Mach.ax then "REG AX"
     else if r = Mach.bx then "REG BX"
     else if r = Mach.tr then "REG TR"
     else if r = Mach.zr then "REG ZR"
     else "R[" ^ (string_of_int r) ^ "]"
  | L_DREF (l, i) -> "DREF(" ^ (loc2str l) ^ ", " ^ (string_of_int i) ^ ")"

(*
 * Generate code for Abstract Machine MACH 
 *)
(* pat2code : Mach.label -> Mach.label - > loc -> Mono.pat -> Mach.code * venv *)
(* pat cannot have same vid twice, loc makes venv?? *)
let pat2code saddr faddr location pattern = match pattern with
Mono.P_WILD -> (Mach.clist [Mach.LABEL saddr], venv0)
|Mono.P_INT i ->
 let (loc_code, rvalue) = loc2rvalue location in
 let code = Mach.clist [Mach.JMPNEQ (Mach.ADDR(Mach.CADDR faddr), rvalue, Mach.INT i)] in
    (Mach.cpre [Mach.LABEL saddr] (loc_code @@ code), venv0)
|Mono.P_BOOL b ->
  let (loc_code, rvalue) = loc2rvalue location in
  let code = Mach.clist [Mach.JMPNEQ (Mach.ADDR(Mach.CADDR faddr), rvalue, Mach.BOOL b)] in
    (Mach.cpre [Mach.LABEL saddr] (loc_code @@ code), venv0)
|Mono.P_UNIT ->
    let (loc_code, rvalue) = loc2rvalue location in
  let code = Mach.clist [Mach.JMPNEQ (Mach.ADDR(Mach.CADDR faddr), rvalue, Mach.UNIT)] in
    (Mach.cpre [Mach.LABEL saddr] (loc_code @@ code), venv0)
|Mono.P_VID v ->
|Mono.P_VIDP (v, p) ->
|Mono.P_PAIR (p, p) ->

(* patty2code : Mach.label -> Mach.label -> loc -> Mono.patty -> Mach.code * venv *)
let patty2code saddr faddr location pattern = raise NotImplemented

(* exp2code : env -> Mach.label -> Mono.exp -> Mach.code * Mach.rvalue *)
let exp2code environment saddr expression = match expression with
 Mono.E_INT i -> (Mach.clist [Mach.LABEL saddr], Mach.INT i)
| Mono.E_BOOL b -> (Mach.clist [Mach.LABEL saddr], Mach.BOOL b)
| Mono.E_UNIT -> (Mach.clist [Mach.LABEL saddr], Mach.UNIT b)
| Mono.E_PLUS -> raise OperatorError
| Mono.E_MINUS -> raise OperatorError
| Mono.E_MULT -> raise OperatorError
| Mono.E_EQ -> raise OperatorError
| Mono.E_NEQ -> raise OperatorError
| Mono.E_VID v -> raise NotImplemented
| Mono.E_FUN f -> raise NotImplemented
| Mono.E_APP (expty1, expty2) -> 
    (match expty1 with

     Mono.E_PLUS -> (match expty2 with
        Mono.E_PAIR (Mono.E_INT a, Mono.E_INT b) -> (Mach.code0, Mach.INT (a+b))
        |Mono.E_PAIR (exp1, exp2) -> 
          let (resultcode1, resultvalue1) =  expty2code environment (Mach.labelNew ()) exp1 and
          let (resultcode2, resultvalue2) =  expty2code environment (Mach.labelNew ()) exp2
        in ()
        | _ -> raise OperatorError) 

    | Mono.E_MINUS -> (match expty2 with
        Mono.E_PAIR (Mono.E_INT a, Mono.E_INT b) -> (Mach.code0, Mach.INT (a-b))
        |Mono.E_PAIR (exp1, exp2) -> 
          let (resultcode1, resultvalue1) =  expty2code environment (Mach.labelNew ()) exp1 and
          let (resultcode2, resultvalue2) =  expty2code environment (Mach.labelNew ()) exp2
        in ()
        | _ -> raise OperatorError)

    | Mono.E_MULT -> (match expty2 with
        Mono.E_PAIR (Mono.E_INT a, Mono.E_INT b) -> (Mach.code0, Mach.INT (a*b))
        |Mono.E_PAIR (exp1, exp2) -> 
          let (resultcode1, resultvalue1) =  expty2code environment (Mach.labelNew ()) exp1 and
          let (resultcode2, resultvalue2) =  expty2code environment (Mach.labelNew ()) exp2
        in ()
        | _ -> raise OperatorError)

    | Mono.E_EQ -> (match expty2 with
        Mono.E_PAIR (Mono.E_INT a, Mono.E_INT b) -> (Mach.code0, Mach.BOOL (a=b))
        |Mono.E_PAIR (exp1, exp2) -> 
          let (resultcode1, resultvalue1) =  expty2code environment (Mach.labelNew ()) exp1 and
          let (resultcode2, resultvalue2) =  expty2code environment (Mach.labelNew ()) exp2
        in ()
        | _ -> raise OperatorError)

    | Mono.E_NEQ -> (match expty2 with
        Mono.E_PAIR (Mono.E_INT a, Mono.E_INT b) -> (Mach.code0, Mach.BOOL (a<>b))
        |Mono.E_PAIR (exp1, exp2) -> 
          let (resultcode1, resultvalue1) =  expty2code environment (Mach.labelNew ()) exp1 and
          let (resultcode2, resultvalue2) =  expty2code environment (Mach.labelNew ()) exp2
        in ()
        | _ -> raise OperatorError)

    | _ -> raise NotImplemented)
| Mono.E_PAIR (expty1, expty2) -> raise NotImplemented
| Mono.E_LET (d, e) -> raise NotImplemented

(* expty2code : env -> Mach.label -> Mono.expty -> Mach.code * Mach.rvalue *)
let expty2code environment saddr expression = raise NotImplemented

(* dec2code : env -> Mach.label -> Mono.dec -> Mach.code * env *)
(* val rec pat = exp can be used only to create functions, exp must have form of 'fn mlist'
   no conbinding have duplicate value identifiers, 'datatype t = A | A of int' is invalid.
*)
let dec2code environment saddr declaration = match declaration with
 Mono.D_VAL (pty,ety)-> raise NotImplemented
| Mono.D_REC (pty, ety)-> raise NotImplemented
| Mono.D_TYPE -> raise NotImplemented

(* mrule2code : env -> Mach.label -> Mono.mrule -> Mach.code *)
let mrule2code environment saddr matchrule = raise NotImplemented

(* program2code : Mono.program -> Mach.code *)
let program2code (dlist, et) = raise NotImplemented
