## Rating System

> _Ideally no vanity metrics / no "like-addiction"._

## Idea

* users can rate every post they read
* we only show the rating under the post to the user that rated it
* all ratings will act like bookmarks for the users themselves, allowing to search and filter rated content
* the ratings will not be shown under the post to anyone else
* the team owning the post will not be informed or see the rating
* instead we will calculate a "popularity score" out of the:
  * number of views
  * number of ratings
  * the ratings (converted to points)
* we will not show the popularity score, but an indicator only to the team owning the post, how popular it is compared to their other posts
* the indicator will likely just be a color gradient
  * green => more popular
  * golden => good average
  * red => less popular

## Benefits

* works as bookmark system
* gives creators feedback if their content is popular
* can be used for suggestions

## Star Rating - but the German way

  * 🙁 / ⭐ (-3 points) "Horrible, absolute waste of my time" 
  * 😐 / ⭐⭐  (-1 point) "I do not like it, it's not to my taste"
  * 🙂 / ⭐⭐⭐ (+ 1 point) "It is good, I like it"
  * 😃 / ⭐⭐⭐⭐ (+ 3 points) "Great content, I'd love to see more like this"
  * 🤩 / ⭐⭐⭐⭐⭐ (+ 5 points) "Awesome, fantastic content, some of the best I've seen, absolutely loving it"

## Popularity Score calculation

* for new posts every night for the first 14 days
* for older posts every week or when the number of views is 5% higher than when the last calculation was done
* for posts older than 3 months, only when the number of views is 10% higher than when the last calculation was done

The formula could go something like:

* "Number of Ratings" / "Number of Views" => "Engagement"
* "Sum of Rating Points" / "Number of Ratings" => "Average Rating"
* "Engagement" * "Average Rating" => "Post Score"

And then compate the current post's score with the average or median scores (maybe ignoring the top and bottom scores) to see how much better or worse it compares. Normalize and map this against our color gradients to display it for the team that owns the posts.

## Data structure

* Use a separate table to track all ratings and use this for the "bookmark" functionality
  * user.yid
  * post.yid
  * team.yid (that owns the post)
  * rating
  * date_rated
* Use a separate table to persist the number views
  * post.yid
  * team.yid (that owns the post)
  * number of views
* Use a separate table to persist the number of views and ratings and score after every calculation
  * post.yid
  * team.yid (that owns the post)
  * score
  * number_of_views
  * number_of_ratings
  * sum_of_ratings
  * calculated_at
