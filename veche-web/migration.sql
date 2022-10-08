ALTER TABLE issue ADD COLUMN poll VARCHAR NULL;
UPDATE issue SET poll = "BySignerWeight" WHERE poll IS NULL;

ALTER TABLE issue
    ADD COLUMN forum
    INTEGER NOT NULL REFERENCES forum ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE forum (
    id                  INTEGER PRIMARY KEY,
    title               VARCHAR NOT NULL,
    access_issue_read   VARCHAR NOT NULL
);
