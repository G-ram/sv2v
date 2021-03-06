{- sv2v
 - Author: Zachary Snow <zach@zachjs.com>
 -}
module Language.SystemVerilog.Parser
    ( parseFiles
    ) where

import Control.Monad.Except
import qualified Data.Map.Strict as Map
import Language.SystemVerilog.AST (AST)
import Language.SystemVerilog.Parser.Lex (lexFile, Env)
import Language.SystemVerilog.Parser.Parse (parse)

-- parses a compilation unit given include search paths and predefined macros
parseFiles :: [FilePath] -> [(String, String)] -> Bool -> [FilePath] -> IO (Either String [AST])
parseFiles includePaths defines siloed paths = do
    let env = Map.map (\a -> (a, [])) $ Map.fromList defines
    runExceptT (parseFiles' includePaths env siloed paths)

-- parses a compilation unit given include search paths and predefined macros
parseFiles' :: [FilePath] -> Env -> Bool -> [FilePath] -> ExceptT String IO [AST]
parseFiles' _ _ _ [] = return []
parseFiles' includePaths env siloed (path : paths) = do
    (ast, envEnd) <- parseFile' includePaths env path
    let envNext = if siloed then env else envEnd
    asts <- parseFiles' includePaths envNext siloed paths
    return $ ast : asts

-- parses a file given include search paths, a table of predefined macros, and
-- the file path
parseFile' :: [String] -> Env -> FilePath -> ExceptT String IO (AST, Env)
parseFile' includePaths env path = do
    result <- liftIO $ lexFile includePaths env path
    (tokens, env') <- liftEither result
    ast <- parse tokens
    return (ast, env')
