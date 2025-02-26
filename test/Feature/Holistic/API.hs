{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE DerivingStrategies    #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NamedFieldPuns        #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}

module Feature.Holistic.API
  ( api
  ) where

import           Data.Morpheus          (interpreter)
import           Data.Morpheus.Document (importGQLDocument)
import           Data.Morpheus.Kind     (SCALAR)
import           Data.Morpheus.Types    (GQLRequest, GQLResponse, GQLRootResolver (..), GQLScalar (..), GQLType (..),
                                         ID (..), IOMutRes, IORes, IOSubRes, ScalarValue (..), SubResolver (..))
import           Data.Text              (Text)
import           GHC.Generics           (Generic)

data TestScalar =
  TestScalar Int
             Int
  deriving (Show, Generic)

instance GQLType TestScalar where
  type KIND TestScalar = SCALAR

instance GQLScalar TestScalar where
  parseValue _ = pure (TestScalar 1 0)
  serialize (TestScalar x y) = Int (x * 100 + y)

data EVENT =
  EVENT
  deriving (Show, Eq)

importGQLDocument "test/Feature/Holistic/API.gql"

resolveValue :: Monad m => b -> a -> m b
resolveValue = const . return

rootResolver ::
     GQLRootResolver IO EVENT () (Query IORes) (Mutation (IOMutRes EVENT ())) (Subscription (IOSubRes EVENT ()))
rootResolver =
  GQLRootResolver
    { queryResolver = return Query {user, testUnion = const $ return Nothing}
    , mutationResolver = return Mutation {createUser = user}
    , subscriptionResolver =
        return Subscription {newUser = const SubResolver {subChannels = [EVENT], subResolver = user}}
    }
  where
    user _ =
      return $
      User
        { name = resolveValue "testName"
        , email = resolveValue ""
        , address = resolveAddress
        , office = resolveAddress
        , friend = resolveValue Nothing
        }
      where
        resolveAddress _ =
          return Address {city = resolveValue "", houseNumber = resolveValue 0, street = resolveValue Nothing}

api :: GQLRequest -> IO GQLResponse
api = interpreter rootResolver
