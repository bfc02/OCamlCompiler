(* 
                         CS 51 Final Project
                      MiniML -- Lexical Analyzer

 *)

{
  open Printf ;;
  open Miniml_parse ;; (* need access to parser's token definitions *)

  let create_hashtable size init =
    let tbl = Hashtbl.create size in
    List.iter (fun (key, data) -> Hashtbl.add tbl key data) init;
    tbl

  let keyword_table = 
    create_hashtable 8 [
                       ("if", IF);
                       ("in", IN);
                       ("then", THEN);
                       ("else", ELSE);
                       ("let", LET);
                       ("raise", RAISE);
                       ("rec", REC);
                       ("true", TRUE);
                       ("false", FALSE);
                       ("fun", FUNCTION);
                       ("function", FUNCTION);
                       ("mod", MODULO);
                       ("not", NOT);
                     ]
                     
  let sym_table = 
    create_hashtable 8 [
                       ("=", EQUALS);
                       ("<", LESSTHAN);
                       ("<=", LESSTHANOREQUAL);
                       (">", GREATERTHAN);
                       (">=", GREATERTHANOREQUAL);
                       (".", DOT);
                       ("->", DOT);
                       (";;", EOF);
                       ("~-", NEG);
                       ("+", PLUS);
                       ("+.", PLUS);
                       ("-", MINUS);
                       ("-.", MINUS);
                       ("*", TIMES);
                       ("*.", TIMES);
                       ("/", DIVIDE);
                       ("/.", DIVIDE);
                       ("(", OPEN);
                       (")", CLOSE);
                       ("^", CONCAT);
                       ("&&", AND);
                       ("||", OR);
                       ("<>", EXCLUSIVEOR);
                     ]
}


let digit = ['0'-'9']
let float_digit = ['0'-'9'] ['.']*
let id = ['a'-'z'] ['a'-'z' '0'-'9']*
let sym = ['(' ')'] | (['$' '&' '*' '+' '-' '/' '=' '<' '>' '^'
                            '.' '~' ';' '!' '?' '%' ':' '#' '|']+)
let strings = ['"'] [^ '"']* ['"']
let hexes = ['0'] ['x'] ['A'-'F' 'a'-'f' '0'-'9']+


rule token = parse
  | digit+ as inum
        { let num = int_of_string inum in
          INT num
        }
  | float_digit+ as ifloat
        { let flo = float_of_string ifloat in 
          FLOAT flo
        }
  | id as word
        { try
            let token = Hashtbl.find keyword_table word in
            token 
          with Not_found ->
            ID word
        }
  | sym as symbol
        { try
            let token = Hashtbl.find sym_table symbol in
            token
          with Not_found ->
            printf "Ignoring unrecognized token: %s\n" symbol;
            token lexbuf
        }
  | strings as str 
        {
          STRING (String.sub str 1 (String.length str - 2))
        }
  | hexes as hex 
        { let h = int_of_string hex in
          INT h
        }
  | '{' [^ '\n']* '}'   { token lexbuf }    (* skip one-line comments *)
  | [' ' '\t' '\n']     { token lexbuf }    (* skip whitespace *)
  | _ as c                                  (* warn and skip unrecognized characters *)
        { printf "Ignoring unrecognized character: %c\n" c;
          token lexbuf
        }
  | eof
        { raise End_of_file }
