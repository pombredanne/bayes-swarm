# Introduction #

Starting from [revision 239](https://code.google.com/p/bayes-swarm/source/detail?r=239) ( see [issue #8](https://code.google.com/p/bayes-swarm/issues/detail?id=#8) for further info ) PrototypeOne has the added feature of optionally storing the webpages analyzed in each extraction cycle. Starting from [revision 367](https://code.google.com/p/bayes-swarm/source/detail?r=367), Pulsar (the renewed extraction engine) changed and enriched the format used by stored webpages.

# Details for HTML pages #

The component that is responsible for extracting and saving the contents of web pages and RSS feeds is [swarm\_wave](http://code.google.com/p/bayes-swarm/source/browse/trunk/pulsar/component/swarm_wave.rb) .

Its execution is configured with a YAML file. The `yml` options file defines :
  * if file storage is active
  * the base folder where webpages will be stored.

If active, file storage archives webpages using the following folder structure :
```
base_folder/yyyy/mm/dd/url_md5/contents.html
```
where :
  * `yyyy/mm/dd` refer to the extraction date
  * `url_md5` is the MD5-hash of the page URL

An additional file
```
base_folder/yyyy/mm/dd/META
```
is created and contains the mapping between all the URLs and their respective MD5 hashes.

Starting from [revision 367](https://code.google.com/p/bayes-swarm/source/detail?r=367), the `META` file contains also additional information, such as the original page id, kind (url, rss, rssitem) and language.

# Details for RSS pages #

When parsing RSS feeds, some additional considerations apply :
  * `url_md5` refers to the URL of the RSS feed
  * each `yyyy/mm/dd/url_md5` contains all the **new** articles published on the feed between last scan time and current extraction date
  * `yyyy/mm/dd/url_md5/contents.html` contains the XML code for extracted feed (yeah, the naming is a bit inconsistent, but it is here for historical reasons).
  * for each article, the file `yyyy/mm/dd/url_md5/article_md5/contents.html` contains the HTML code for the specific article. `article_md5` is the MD5-hash of the article URL ( extracted from the RSS feed )
  * a `META` file `yyyy/mm/dd/url_md5/META` is created to store the mapping between all the article URLs for the given feed and their respective MD5 hashes. Starting from [revision 367](https://code.google.com/p/bayes-swarm/source/detail?r=367), this `META` contains also the id of the rss feed, the kind (`rssitem`) and language of the feed.

# Historical Notes and Migrations #

[Revision 367](https://code.google.com/p/bayes-swarm/source/detail?r=367) restructured the format of the PageStore. The most notable changes are:
  1. each META file contains extra informations ( see later section )
  1. the `contents.html` for an rss feed no longer contains the concatenation of all the feed items, but the original xml contents of the feed itself.

The component [swarm\_moremeta](http://code.google.com/p/bayes-swarm/source/browse/trunk/pulsar/component/swarm_moremeta.rb) can be used to migrate `META` files from the previous contents to the new enriched ones.

However, it **does not migrate** the `contents.html` file for RSS feeds.

# META file structure #

The are 2 possible kinds of meta files. One describing the storage for `url`s and `rss` feeds. The other describing the storage for single items within an `rss` feed.

The former uses this structure:
```
[md5_url_hash] [url] [page_id] [page_kind] [page_language]
```

Example:
```
afa4d5c1593694b1af94aad132a53da7 http://www.economist.com/ 180 url en
```

The latter uses a similar format:
```
[md5_feed_item_url_hash] [feed_item_url] [rss_feed_id] rssitem [page_language]
```

Example:
```
dfd3a4418ef49315062a0d32f1bccfa5 http://feeds.feedburner.com/.../blah.html 158 rssitem en
```

**Remember**: Rss items do not have an associated id, so the reported `id` and `language` refer to the RSS feed the item belongs to.

# Example File Storage Folder Structure #
```
pagestore_root/
  2008/
    11/
      15/
        META                                   # top META file for urls and rss feeds
        a34ceec55bf49d19b32ae44623cd01d8/      # webpage and its contents
          contents.html
        eb0c7650efe1f390a96d3b074507415e/
          contents.html
        ...
        54969c4ae977d5c4e71ce941047488ad/      # Rss feed storage structure
          META                                 # META file for rss items
          contents.html                        # XML contents of the RSS feed
          370534164667831c4dddb21cc72fa4c3/    # Rss feed item and its contents
            contents.html
          2a1b5d3b26d1f65958389e9cdd571cb4/    # Another feed item...
            contents.html
  2008/
    11/
      16/
        META
        ...
```