{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Handler.Forum (
    getForumR,
    getForumsR,
) where

import Import

import Data.Map.Strict qualified as Map

import Genesis (forums)
import Model.Forum qualified as Forum
import Model.Issue qualified as Issue
import Model.User qualified as User
import Templates.Issue (issueTable)

getForumR :: ForumId -> Handler Html
getForumR forumId = do
    Entity _ user <- requireAuth

    mState <- lookupGetParam "state"
    let stateOpen = mState /= Just "closed"
    forumE@(_, Forum{title}) <- Forum.getEntity404 forumId
    issues <- Issue.listForumIssues forumE $ Just stateOpen
    (openIssueCount, closedIssueCount) <- Issue.countOpenAndClosed forumId

    mSignerId <- User.getSignerId user
    mHolderId <- User.getHolderId user
    let isAddForumIssueAllowed =
            isAllowed $ AddForumIssue forumE (mSignerId, mHolderId)

    defaultLayout $(widgetFile "forum")

getForumsR :: Handler Html
getForumsR = do
    groups <- do
        mUser <- maybeAuth
        case mUser of
            Nothing -> pure (Nothing, Nothing)
            Just (Entity _ user) ->
                (,) <$> User.getSignerId user <*> User.getHolderId user
    let isReadAllowed forumE = isAllowed $ ReadForum forumE groups
    defaultLayout $(widgetFile "forums")
