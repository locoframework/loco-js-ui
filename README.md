![logo](https://raw.githubusercontent.com/artofcodelabs/artofcodelabs.github.io/master/assets/ext/loco_logo_trans_sqr-300px.png)

> Loco-JS-UI connects Loco-JS-Model with UI elements on a page

# 🧐 What is Loco-JS-UI?

Loco-JS-UI is an optional part of the Loco framework. It can be used with Loco-JS to connect models with UI elements like forms. Models are created using Loco-JS-Models and connect JavaScript objects with their representation on the back-end.

Loco-JS-UI supports only form at this moment throughout all UI elements.

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
        |--- other parts of Loco-JS

        Loco-JS-UI - connects models with UI elements (extracted to a separate library)
```

# 📝 UI.Form

`UI.Form` is a class that connects a model instance with a form.  
It is useful to allow users to modify the model's attributes.  
`UI.Form` converts attributes of the model's instance to the values of the corresponding form elements.  
It delivers a front-end validation without an extra effort and it turns a standard static form into a dynamic, submitted asynchronously one.

Example:

```javascript
import { UI } from "loco-js-ui";
import User from "models/User";

// ...

const active = () => {
  console.log("Your account is being created...");
}

const failure = () => {
  console.log("Creation failed or front-end validation hasn't passed.");
}

const created = data => {
  subscribe({ to: new User({ id: data.id }), with: receivedSignal });
  document.querySelector("form").style.display = "none";
  renderFlash({ notice: data.notice });
};

export default () => {
  const form = new UI.Form({
    for: new User(), // (optional) model instance connected with the form
    id: "new_user",  // (optional) the ID attribute of the HTML <form> element.
                     // If not passed - it is resolved based on the value of model's ID property to:
                     // * `edit_${lowercased model's identity property}_${model's ID}` - if present
                     // * `new_${lowercased model's identity property}` - if null
    initObj: false,  // (optional) determines whether to initialize the passed object based
                     // on the value of the corresponding form elements.
                     // False by default (object retains the initial attribute values)
    callbackActive: active,   // (optional) function called after sending the request
    callbackFailure: failure  // (optional) function called if an object is invalid
                              // on the front-end or back-end side (400 HTTP status code)
    callbackSuccess: created  // (optional) function called on success
  });
  form.render();
};
```

From the HTML perspective - the following example shows how a form should be structured.
What you should pay attention to is that all tags related to given attribute, should be wrapped by a tag with a proper **data-attr** attribute. The value of this attribute should match the **remote name** of given attribute (the name of the corresponding attribute on the server side, returned by an API).

Look at how errors are expressed. The tag is irrelevant, only **errors** class and **data-for** HTML attribute are important.

```html
<form id="coupon-form">
  <p data-attr="stripe_id">
    <label>Stripe ID</label><br>
    <input type="text" />
    <span class="errors" data-for="stripe_id"></span>
  </p>

  <p data-attr="amount_off">
    <input type="radio" name="amount_off" value="0" />
    <label>$0 off</label>

    <input type="radio" name="amount_off" value="20" />
    <label>$20 off</label>

    <input type="radio" name="amount_off" value="50" />
    <label>$50 off</label>

    <span class="errors" data-for="amount_off"></span>
  </p>

  <p data-attr="percent_off">
    <input type="hidden" name="percent_off" value="0" />

    <input type="checkbox" name="percent_off" value="50" />
    <label>50% off</label>

    <span class="errors" data-for="percent_off"></span>
  </p>

  <p data-attr="duration">
    <label>Duration</label><br>
    <select>
      <option value="forever">Forever</option>
      <option value="once">Once</option>
      <option value="repeating">Repeating</option>
    </select>
  </p>

  <p data-attr="duration_in_months">
    <label>Duration in months</label><br>
    <input type="text" />
    <span class="errors" data-for="duration_in_months"></span>
  </p>

  <p>
    <input type="submit" value="Submit" />
    <span class="errors" data-for="base"></span>
  </p>
</form>
```

Remember that when you submitting a form, **all model attributes** are sent to the server and not only those available to modify via the form fields.
Model's attribute can be an object as well - for example, if you want to send a nested resources.

If model's ID is `null`, the instance is considered as new, not persisted on the server, so after submitting a form, Loco-JS will send the following XHR request:

```bash
Started POST "/admin/plans/7/coupons"
Parameters: {"coupon"=>{"stripe_id"=>"my-project-test", "percent_off"=>50, "amount_off"=>"0", "duration"=>"repeating", "duration_in_months"=>6, "max_redemptions"=>nil, "redeem_by"=>nil}, "plan_id"=>"7"}
```

On the other hand, if model instance has not null ID, Loco-JS sends the following XHR request to the server.

```bash
Started PUT "/admin/plans/9/coupons/100"
Parameters: {"coupon"=>{"stripe_id"=>"my-project-test", "percent_off"=>0, "amount_off"=>"50", "duration"=>"once", "duration_in_months"=>nil, "max_redemptions"=>nil, "redeem_by"=>nil}, "plan_id"=>"9", "id"=>"100"}
```

The success response from the server should be in the JSON format with the following structure:

```javascript
{
  "success": true,
  "status": 200,
  "data": {      // (optional) this object that will be passed to
    "id": 123,   // callbackSuccess if this function is defined
    "foo": "bar"
  },
  "flash": {                              // (optional) UI.Form changes the value
    "success": "Coupon has been created!" // of submit button depending on the current
  },                                      // state of the form and this key represents
                                          // the success state (a record has been saved)
  "access_token": "123qweasd" // (optional) when access_token is returned you can then
                              // emit on the server a signal assigned to that token
}
```

The example of the failure response:

```javascript
{
  "success": false,
  "status": 400,
  "errors": {
    "stripe_id": ["has already been taken"],
    "base": ["something wrong with the whole object"]
  }
}
```

# 📜 License

Loco-JS-UI is released under the [MIT License](https://opensource.org/licenses/MIT).

# 👨‍🏭 Author

Zbigniew Humeniuk from [Art of Code](http://artofcode.co)