![logo](https://raw.githubusercontent.com/artofcodelabs/artofcodelabs.github.io/master/assets/ext/loco_logo_trans_sqr-300px.png)

> Loco-JS-UI connects Loco-JS-Model with UI elements on a page

# 🧐 What is Loco-JS-UI?

Loco-JS-UI is an optional part of the Loco framework. It can be used along with [Loco-JS](https://github.com/locoframework/loco-js) to connect models with UI elements like forms. Models are created using [Loco-JS-Model](https://github.com/locoframework/loco-js-model) and they connect JavaScript objects with their representation on the back-end.

Loco-JS-UI supports only a **\<form\>** element throughout all HTML elements at this moment.

*Visualization of the Loco framework:*

```
Loco Framework
|
|--- Loco-Rails (back-end part)
|       |
|       |--- Loco-Rails-Core (logical structure for JS / can be used separately with Loco-JS-Core)
|
|--- Loco-JS (front-end part)
        |
        |--- Loco-JS-Core (logical structure for JS / can be used separately)
        |
        |--- Loco-JS-Model (model part / can be used separately)
        |
        |--- other built-in parts of Loco-JS

        Loco-JS-UI - connects models with UI elements (a separate library)
```

# 📝 UI.Form

`UI.Form` is a class that connects a model instance with a form. It allows users to modify model attributes.  
`UI.Form` converts attributes of the model's instance to values of the corresponding form elements.  
It delivers a front-end validation without an extra effort, and it turns a standard static form into a dynamic, submitted asynchronously one.

Example:

```javascript
import { UI } from "loco-js-ui";
import CommentModel from "models/article/Comment";

// ...

const active = () => {
  console.log("The comment is being updated...");
}

const failure = () => {
  console.log("Update failed or front-end validation hasn't passed.");
}

const updated = data => {
  document.querySelector("form").style.display = "none";
  renderFlash({ notice: data.notice });
};

export default (opts = {}) => {
  const form = new UI.Form({
    for: new CommentModel({ id: opts.commentId, resource: "admin" }),
        // (optional) a model instance connected with the form
    id: `edit_comment_${opts.commentId}`, 
        // (optional) the ID attribute of the HTML <form> element.
        // If not passed - it is resolved based on the value of a model's ID property to:
        // * if present => `edit_${lowercased model's identity property}_${model's ID}`
        // * if null => `new_${lowercased model's identity property}`
    initObj: true,  // (optional) determines whether to initialize the passed object based
                    // on values of the corresponding form elements.
                    // False by default (object retains the initial attribute values)
    callbackActive: active,   // (optional) function called after sending the request
    callbackFailure: failure  // (optional) function called if an object is invalid
                              // on the front-end or back-end side (400 HTTP status code)
    callbackSuccess: updated  // (optional) function called on success
  });
  form.render();
};
```

From the HTML perspective - the following example shows how a form should be structured.
What you should pay attention to is that all tags related to a given attribute should be wrapped in a tag with a proper **data-attr** attribute. The value of this attribute should match the **remote name** of the given attribute (the name of the corresponding attribute on the server-side, returned by an API). This value is configurable in the model.

Look at how errors are expressed. The tag is irrelevant. Only **errors** class and **data-for** HTML attribute are essential.

```html
<form id="edit_comment_1" 
      action="https://example.com/admin/articles/1/comments/1" 
      accept-charset="UTF-8" 
      method="post">
      
  <p data-attr="author">
    <label for="comment_author">Author</label> <br>
    <input type="text" value="Tom" name="comment[author]" id="comment_author" />
    <span class="errors" data-for="author"></span>
  </p>

  <p data-attr="text">
    <label for="comment_text">Text</label> <br>
    <textarea name="comment[text]" id="comment_text">Interesting article.</textarea>
    <span class="errors" data-for="text"></span>
  </p>

  <div data-attr="article_id">
    <input type="hidden" value="1" name="comment[article_id]" id="comment_article_id" />
  </div>

  <div data-attr="pinned">
    <input name="comment[pinned]" type="hidden" value="0" />
    <input type="checkbox" value="1" name="comment[pinned]" id="comment_pinned" /> 
    <label for="comment_pinned">Pinned</label>
  </div>

  <div data-attr="admin_rate">
    <label for="comment_admin_rate">Rate</label>
    <select name="comment[admin_rate]" id="comment_admin_rate">
      <option value="1">Awful</option>
      <option value="2">Bad</option>
      <option selected="selected" value="3">Decent</option>
      <option value="4">Good</option>
      <option value="5">Amazing</option>
    </select>
  </div>

  <div data-attr="emotion">
    <input type="radio" value="-1" name="comment[emotion]" id="comment_emotion_-1" /> 
    <label for="comment_emotion_-1">Negative</label>
    
    <input type="radio" value="0" checked="checked" name="comment[emotion]" id="comment_emotion_0" /> 
    <label for="comment_emotion_0">Neutral</label>
    
    <input type="radio" value="1" name="comment[emotion]" id="comment_emotion_1" /> 
    <label for="comment_emotion_1">Positive</label>
  </div>

  <p>
    <input type="submit" name="commit" value="Update Comment" />
  </p>
</form>
```

Keep in mind that a form submission sends **all model attributes** to the server. Sent attributes are not limited to only these available for modification via form fields. A value of a model's attribute can be an object as well. For example, if you want to send nested resources.

A model's instance is considered as new, not persisted on the server if the value of the ID attribute is `null`. Loco-JS will send the following XHR request upon form submission in this case.

```bash
Started POST "/admin/articles/1/comments"
Parameters: {"comment":{"author":"Tommy","text":"Interesting article.","article_id":1,"created_at":null,"updated_at":null,"emotion":0,"pinned":false,"admin_rate":3,"approved":null}}
```

On the other hand, if the value of the model's instance ID attribute is not null, Loco-JS-UI sends the following XHR request to the server.

```bash
Started PUT "/admin/articles/1/comments/1"
Parameters: {"comment":{"author":"Tommy","text":"Interesting article.","article_id":1,"created_at":null,"updated_at":null,"emotion":0,"pinned":false,"admin_rate":3,"approved":null}}
```

The success response from the server must be in the JSON format with the following structure:

```javascript
{
  "success": true,
  "status": 200,
  "data": {      // (optional) this object is passed to
    "id": 123,   // callbackSuccess if defined
    "notice": "foo bar baz"
  },
  "flash": {                               // (optional) UI.Form changes the value
    "success": "Comment has been updated!" // of a submit button to this on success
  },
  "access_token": "123qweasd" // (optional) it is possible to send a signal from the server
                              // assigned to the returned access_token
}
```

The example of the failure response:

```javascript
{
  "success": false,
  "status": 400,
  "errors": {
    "text": ["is vulgar"],
    "base": ["something is wrong with the whole object"]
  }
}
```

# 📥 Installation

```bash
$ npm install --save loco-js-ui
```

# 🤝 Dependencies

🎊 Loco-JS-UI has no dependencies. 🎉

# ⚙️ Configuration

Loco-JS-UI is usable only along with Loco-JS.  
The following code shows how to connect both libraries.

```javascript
import { connector } from "loco-js";
import { connect } from "loco-js-ui";

connect(connector);
```

# 📜 License

Loco-JS-UI is released under the [MIT License](https://opensource.org/licenses/MIT).

# 👨‍🏭 Author

Zbigniew Humeniuk from [Art of Code](https://artofcode.co)
