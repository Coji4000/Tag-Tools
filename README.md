# tag shuffler

A pair of scripts to aid in retrieving a current list of tags available on e621 and Danbooru and Shuffling the results into a prompt format.
fetch-Taglists.ps1 will install https://github.com/DraconicDragon/danbooru-e621-tag-list-processor and use it to get the taglists, store Krita compatible autofill csvs. fetch-Taglists.ps1 then creates it's own file that is a prune list of just the tag names.

shuffle-Taglist.ps1 opens a WPF UI allowing a User to select a taglist, provide a few configuration settings, and click execute to retrieve a random prompt in the length specified.