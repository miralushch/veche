{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Authorization where

-- global
import Control.Monad (unless)
import Yesod.Core (MonadHandler, permissionDenied)
import Yesod.Persist (Entity (Entity))

-- component
import Model (Issue (Issue), UserId, UserRole (UserRole))
import Model qualified
import Model.Types (EntityForum, Forum (Forum), Poll (..),
                    Role (Admin, MtlSigner), Roles)
import Model.Types qualified

-- | Use 'Entity' or 'Key' ({entity}Id)
-- when presence in the database is required.
data AuthzRequest
    = ListForums
    | ReadForum             EntityForum Roles
    | AddForumIssue         EntityForum Roles
    | ReadForumIssue        EntityForum Roles
    | AddForumIssueComment  EntityForum Roles
    | AddIssueVote      (Entity Issue)  Roles
    | EditIssue         (Entity Issue) UserId
    | CloseReopenIssue  (Entity Issue) UserId
    | AdminOp (Entity UserRole)

isAllowed :: AuthzRequest -> Bool
isAllowed = \case
    ListForums -> True
    ReadForum               forum roles -> checkForumRoles forum roles
    AddForumIssue           forum roles -> checkForumRoles forum roles
    ReadForumIssue          forum roles -> checkForumRoles forum roles
    AddForumIssueComment    forum roles -> checkForumRoles forum roles
    AddIssueVote (Entity _ Issue{poll}) roles -> checkVote poll roles
    EditIssue        issue user -> authzEditIssue issue user
    CloseReopenIssue issue user -> authzEditIssue issue user
    AdminOp (Entity _ UserRole{role}) -> role == Admin
  where
    authzEditIssue (Entity _ Issue{author}) user = author == user

checkForumRoles :: EntityForum -> Roles -> Bool
checkForumRoles (_, Forum{requireRole}) roles = all (`elem` roles) requireRole

checkVote :: Maybe Poll -> Roles -> Bool
checkVote mPoll roles =
    case mPoll of
        Nothing             -> False
        Just BySignerWeight -> MtlSigner `elem` roles

requireAuthz :: MonadHandler m => AuthzRequest -> m ()
requireAuthz req = unless (isAllowed req) $ permissionDenied ""
