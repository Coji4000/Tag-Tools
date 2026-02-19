## Tag Tools

A pair of scripts to aid in retrieving a current list of tags available on e621 and Danbooru and Shuffling the results into a prompt format.


**shuffleTaglists.ps1**
 - Opens a WPF UI
 - Allows selection of a csv or txt input list
 - Range options allow targetting smaller chunks of the file
 - Prompt length specifies the number of items to retrieve
 - Pressing Execute retrieves the items and displays them
 - Easy to copy and paste into whatever may be asking you for prompts
 - Sample input format included below


**fetch-Taglists.ps1** 
 - Requires git
 - Installs https://github.com/DraconicDragon/danbooru-e621-tag-list-processor
 - Runs the processor to pull current taglists from Danbooru and e621
 - Further processes the output from the processor into the format shown below


```
pink
red
!(4000
a b c d
Frank
0_0
We've been trying to reach you
...
```

