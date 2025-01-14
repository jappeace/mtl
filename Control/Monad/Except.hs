{-# LANGUAGE Safe #-}
{- |
Module      :  Control.Monad.Except
Copyright   :  (c) Michael Weber <michael.weber@post.rwth-aachen.de> 2001,
               (c) Jeff Newbern 2003-2006,
               (c) Andriy Palamarchuk 2006
License     :  BSD-style (see the file LICENSE)

Maintainer  :  libraries@haskell.org
Stability   :  experimental
Portability :  non-portable (multi-parameter type classes)

[Computation type:] Computations which may fail or throw exceptions.

[Binding strategy:] Failure records information about the cause\/location
of the failure. Failure values bypass the bound function,
other values are used as inputs to the bound function.

[Useful for:] Building computations from sequences of functions that may fail
or using exception handling to structure error handling.

[Example type:] @'Either' String a@

The Error monad (also called the Exception monad).

@since 2.2.1
-}

{-
  Rendered by Michael Weber <mailto:michael.weber@post.rwth-aachen.de>,
  inspired by the Haskell Monad Template Library from
    Andy Gill (<http://web.cecs.pdx.edu/~andy/>)
-}
module Control.Monad.Except
  (
    -- * Warning
    -- $warning
    -- * Monads with error handling
    Error.MonadError(..),
    Error.liftEither,
    Error.tryError,
    Error.withError,
    Error.handleError,
    Error.mapError,
    -- * Example 1: Custom Error Data Type
    -- $customErrorExample

    -- * Example 2: Using ExceptT Monad Transformer
    -- $ExceptTExample
  ) where

import qualified Control.Monad.Error.Class as Error

{- $warning
Please do not confuse 'ExceptT' and 'throwError' with 'Control.Exception.Exception' /
'Control.Exception.SomeException' and 'Control.Exception.catch', respectively. The latter
are for exceptions built into GHC, by default, and are mostly used from within the IO monad.
They do not interact with the \"exceptions\" in this package at all. This package allows you
to define a new kind of exception control mechanism which does not necessarily need your code to
be placed in the IO monad.

In short, all \"catching\" mechanisms in this library will be unable to catch exceptions thrown
by functions in the "Control.Exception" module, and vice-versa.
-}

{- $customErrorExample
Here is an example that demonstrates the use of a custom error data type with
the 'throwError' and 'catchError' exception mechanism from 'MonadError'.
The example throws an exception if the user enters an empty string
or a string longer than 5 characters. Otherwise it prints length of the string.

>-- This is the type to represent length calculation error.
>data LengthError = EmptyString  -- Entered string was empty.
>          | StringTooLong Int   -- A string is longer than 5 characters.
>                                -- Records a length of the string.
>          | OtherError String   -- Other error, stores the problem description.
>
>-- Converts LengthError to a readable message.
>instance Show LengthError where
>  show EmptyString = "The string was empty!"
>  show (StringTooLong len) =
>      "The length of the string (" ++ (show len) ++ ") is bigger than 5!"
>  show (OtherError msg) = msg
>
>-- For our monad type constructor, we use Either LengthError
>-- which represents failure using Left LengthError
>-- or a successful result of type a using Right a.
>type LengthMonad = Either LengthError
>
>main = do
>  putStrLn "Please enter a string:"
>  s <- getLine
>  reportResult (calculateLength s)
>
>-- Attempts to calculate length and throws an error if the provided string is
>-- empty or longer than 5 characters.
>-- (Throwing an error in this monad means returning a 'Left'.)
>calculateLength :: String -> LengthMonad Int
>calculateLength [] = throwError EmptyString
>calculateLength s | len > 5 = throwError (StringTooLong len)
>                  | otherwise = return len
>  where len = length s
>
>-- Prints result of the string length calculation.
>reportResult :: LengthMonad Int -> IO ()
>reportResult (Right len) = putStrLn ("The length of the string is " ++ (show len))
>reportResult (Left e) = putStrLn ("Length calculation failed with error: " ++ (show e))
-}

{- $ExceptTExample
@'ExceptT'@ monad transformer can be used to add error handling to another monad.
Here is an example how to combine it with an @IO@ monad:

>import Control.Monad.Except
>
>-- An IO monad which can return String failure.
>-- It is convenient to define the monad type of the combined monad,
>-- especially if we combine more monad transformers.
>type LengthMonad = ExceptT String IO
>
>main = do
>  -- runExceptT removes the ExceptT wrapper
>  r <- runExceptT calculateLength
>  reportResult r
>
>-- Asks user for a non-empty string and returns its length.
>-- Throws an error if user enters an empty string.
>calculateLength :: LengthMonad Int
>calculateLength = do
>  -- all the IO operations have to be lifted to the IO monad in the monad stack
>  liftIO $ putStrLn "Please enter a non-empty string: "
>  s <- liftIO getLine
>  if null s
>    then throwError "The string was empty!"
>    else return $ length s
>
>-- Prints result of the string length calculation.
>reportResult :: Either String Int -> IO ()
>reportResult (Right len) = putStrLn ("The length of the string is " ++ (show len))
>reportResult (Left e) = putStrLn ("Length calculation failed with error: " ++ (show e))
-}
