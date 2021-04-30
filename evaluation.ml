(* 
                         CS 51 Final Project
                         MiniML -- Evaluation
*)

(* This module implements a small untyped ML-like language under
   various operational semantics.
 *)

open Expr ;;
  
(* Exception for evaluator runtime, generated by a runtime error in
   the interpreter *)
exception EvalError of string ;;
  
(* Exception for evaluator runtime, generated by an explicit `raise`
   construct in the object language *)
exception EvalException ;;

(*......................................................................
  Environments and values 
 *)

module type ENV = sig
    (* the type of environments *)
    type env
    (* the type of values stored in environments *)
    type value =
      | Val of expr
      | Closure of (expr * env)
   
    (* empty () -- Returns an empty environment *)
    val empty : unit -> env

    (* close expr env -- Returns a closure for `expr` and its `env` *)
    val close : expr -> env -> value

    (* lookup env varid -- Returns the value in the `env` for the
       `varid`, raising an `Eval_error` if not found *)
    val lookup : env -> varid -> value

    (* extend env varid loc -- Returns a new environment just like
       `env` except that it maps the variable `varid` to the `value`
       stored at `loc`. This allows later changing the value, an
       ability used in the evaluation of `letrec`. To make good on
       this, extending an environment needs to preserve the previous
       bindings in a physical, not just structural, way. *)
    val extend : env -> varid -> value ref -> env

    (* env_to_string env -- Returns a printable string representation
       of environment `env` *)
    val env_to_string : env -> string
                                 
    (* value_to_string ?printenvp value -- Returns a printable string
       representation of a value; the optional flag `printenvp`
       (default: `true`) determines whether to include the environment
       in the string representation when called on a closure *)
    val value_to_string : ?printenvp:bool -> value -> string
  end

module Env : ENV =
  struct
    type env = (varid * value ref) list
     and value =
       | Val of expr
       | Closure of (expr * env) ;;

    let empty () : env = [] ;;

    let close (exp : expr) (env : env) : value =
      Closure (exp, env) ;;

    let lookup (env : env) (varname : varid) : value =
      try !(List.assoc varname env)
      with _ -> raise (EvalError ("Variable \"" ^ varname ^ "\" does not exist in the environment")) ;;

    let extend (env : env) (varname : varid) (loc : value ref) : env =
      (varname, loc) :: (List.remove_assoc varname env) ;;

    let env_to_string (env : env) : string =
      let str = ref "" in 
      List.iter (fun (var,_) -> str := (!str ^ var ^ " = NEED TO COMPLETE THIS PART; ")) env ;
      "E{" ^ !str ^ "}" ;; 

    let value_to_string ?(printenvp : bool = true) (v : value) : string =
      match v with
      | Val exp -> "Val: " ^ (exp_to_concrete_string exp)
      | Closure (exp, env) -> 
        "Closure: " ^ (exp_to_concrete_string exp) ^ (
          if printenvp then " in env: " ^ (env_to_string env) ^ ")" 
          else ""
        ) ;;
  end
;;


(*......................................................................
  Evaluation functions

  Each of the evaluation functions below evaluates an expression `exp`
  in an environment `env` returning a result of type `value`. We've
  provided an initial implementation for a trivial evaluator, which
  just converts the expression unchanged to a `value` and returns it,
  along with "stub code" for three more evaluators: a substitution
  model evaluator and dynamic and lexical environment model versions.

  Each evaluator is of type `expr -> Env.env -> Env.value` for
  consistency, though some of the evaluators don't need an
  environment, and some will only return values that are "bare
  values" (that is, not closures). 

  DO NOT CHANGE THE TYPE SIGNATURES OF THESE FUNCTIONS. Compilation
  against our unit tests relies on their having these signatures. If
  you want to implement an extension whose evaluator has a different
  signature, implement it as `eval_e` below.  *)

(* The TRIVIAL EVALUATOR, which leaves the expression to be evaluated
   essentially unchanged, just converted to a value for consistency
   with the signature of the evaluators. *)
   
let eval_t (exp : expr) (_env : Env.env) : Env.value =
  (* coerce the expr, unchanged, into a value *)
  Env.Val exp ;;


(* Helper functions for evaluating unops and binops *)
let eval_unop (un : unop) (Env.Val e : Env.value) : expr = 
  match un,e with 
  | Negate, Num i -> Num ((-1) * i)
  | Negate, Float f -> Float ((-1.0) *. f)
  | _,_ -> raise (EvalError "invalid unop operation \nmake sure to check types") ;;

let eval_binop (bi : binop) (Env.Val e1 : Env.value) (Env.Val e2 : Env.value) : expr =
  match bi,e1,e2 with 
  | Plus, Num i1, Num i2 -> Num (i1 + i2)
  | Plus, Float i1, Float i2 -> Float (i1 +. i2)
  | Minus, Num i1, Num i2 -> Num (i1 - i2)
  | Minus, Float i1, Float i2 -> Float (i1 -. i2)
  | Times, Num i1, Num i2 -> Num (i1 * i2)
  | Times, Float i1, Float i2 -> Float (i1 *. i2)
  | Divide, Num i1, Num i2 -> Num (i1 / i2)
  | Divide, Float i1, Float i2 -> Float (i1 /. i2)
  | Modulo, Num i1, Num i2 -> Num (i1 mod i2)
  | Equals, Bool i1, Bool i2 -> if i1 = i2 then Bool true else Bool false
  | Equals, Num i1, Num i2 -> if i1 = i2 then Bool true else Bool false
  | Equals, Float i1, Float i2 -> 
    (* checks for near equality *)
    if abs_float (i1 -. i2) < 0.00001 then Bool true 
    else Bool false
  | LessThan, Num i1, Num i2 -> if i1 < i2 then Bool true else Bool false
  | LessThan, Float i1, Float i2 -> if i1 < i2 then Bool true else Bool false
  | _,_,_ -> raise (EvalError "invalid binop operation \nmake sure to check types") ;;


(* The SUBSTITUTION MODEL evaluator -- to be completed *)
let eval_s (exp : expr) (_env : Env.env) : Env.value =
  let rec eval_s' (exp' : expr) : expr = 
    match exp' with 
    | Var v -> raise (EvalError ("Unbound variable " ^ v))
    | Num _ | Float _ | Bool _ -> exp'
    | Unassigned | Raise -> raise EvalException
    | Unop (un, e) -> eval_unop un (Env.Val (eval_s' e))
    | Binop (bi, e1, e2) -> eval_binop bi (Env.Val (eval_s' e1)) (Env.Val (eval_s' e2))
    | Conditional (e1, e2, e3) -> (
        match eval_s' e1 with 
        | Bool true -> (eval_s' e2) 
        | Bool false -> (eval_s' e3)
        | _ -> raise (EvalError "expecting bool but received something else")
      )
    | Fun _ -> exp'
    | Let (v, e1, e2) -> eval_s' (subst v (eval_s' e1) e2)
    | Letrec (v, e1, e2) -> 
      let new_e1 = eval_s' (subst v (Letrec (v, e1, Var v)) e1) in 
      eval_s' (subst v new_e1 e2)
    | App (e1, e2) -> 
      match eval_s' e1 with 
      | Fun (v, e) -> eval_s' (subst v (eval_s' e2) e)
      | _ -> raise (EvalError "non-function applied")
  in 
  Env.Val (eval_s' exp) ;;


(* The DYNAMICALLY-SCOPED ENVIRONMENT MODEL evaluator -- to be
   completed *)
let rec eval_d (exp : expr) (env : Env.env) : Env.value =
  match exp with 
  | Var v -> (
      try 
        match Env.lookup env v with 
        | Env.Val new_exp -> Env.Val new_exp
        | Env.Closure (new_exp, new_env) -> eval_d new_exp new_env
      with 
        Not_found -> raise (EvalError ("Unbound variable " ^ v))
    )
  | Num _ | Float _ | Bool _ -> Env.Val exp
  | Unassigned | Raise -> raise EvalException
  | Unop (un, e) -> Env.Val (eval_unop un (eval_d e env))
  | Binop (bi, e1, e2) -> Env.Val (eval_binop bi (eval_d e1 env) (eval_d e2 env))
  | Conditional (e1, e2, e3) -> (
      match eval_d e1 env with 
      | Env.Val (Bool true) -> eval_d e2 env
      | Env.Val (Bool false) -> eval_d e3 env
      | _ -> raise (EvalError "expecting bool but received something else")
    )
  | Fun _ -> Env.close exp (Env.empty ())
  | Let (v, e1, e2) -> 
    let new_e1 = eval_d e1 env in 
    eval_d e2 (Env.extend env v (ref new_e1))
  | Letrec (v, e1, e2) -> 
    let new_val = ref (Env.Val Unassigned) in
    let new_env = Env.extend env v new_val in 
    let new_e1 = eval_d e1 new_env in 
    (match new_e1 with 
    | Env.Val (Var _) -> raise (EvalError "hit variable")
    | _ -> new_val :=  new_e1; eval_d e2 new_env)
  | App (e1, e2) -> 
    let new_val = ref (eval_d e2 env) in 
    match eval_d e1 env with 
    | Env.Closure (Fun (v, e3), _) -> eval_d e3 (Env.extend env v new_val)
    | _ -> raise (EvalError "non-function applied") ;;


(* The LEXICALLY-SCOPED ENVIRONMENT MODEL evaluator -- optionally
   completed as (part of) your extension *)
   
let eval_l (_exp : expr) (_env : Env.env) : Env.value =
  failwith "eval_l not implemented" ;;


(* The EXTENDED evaluator -- if you want, you can provide your
   extension as a separate evaluator, or if it is type- and
   correctness-compatible with one of the above, you can incorporate
   your extensions within `eval_s`, `eval_d`, or `eval_l`. *)

let eval_e _ =
  failwith "eval_e not implemented" ;;


(* Connecting the evaluators to the external world. The REPL in
   `miniml.ml` uses a call to the single function `evaluate` defined
   here. Initially, `evaluate` is the trivial evaluator `eval_t`. But
   you can define it to use any of the other evaluators as you proceed
   to implement them. (We will directly unit test the four evaluators
   above, not the `evaluate` function, so it doesn't matter how it's
   set when you submit your solution.) *)

(* Used to keep track of which model to use *)
type model = Substitution | Dynamic | Lexical | Nil ;;
(* Semantics model we are currently using *)
let current = ref Nil ;;

(* let evaluate = 
  match !current with 
  | Substitution -> eval_s
  | Dynamic -> eval_d
  | Lexical -> eval_l
  | Extended -> eval_e
  | Nil -> raise EvalException ;;  *)


let evaluate = 
  (* USER CREATED *)
  while !current = Nil do 
    let preference = 
      print_string ("\nPlease enter a valid semantics format and press enter:\n" ^
        "(\"s\" for substitution, \"d\" for dynamic)\n"); 
      read_line ()
    in 
    if preference = "s" then current := Substitution
    else if preference = "d" then current := Dynamic 
  done;
  match !current with 
  | Substitution -> eval_s
  | Dynamic -> eval_d
  | Lexical -> eval_l
  | Nil -> raise EvalException ;;
