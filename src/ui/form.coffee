import Deps from '../deps';
import DomUtils from "../utils/dom.coffee";
import CollectionUtils from "../utils/collection.coffee";
import ArrayUtils from "../utils/array.coffee";

class Form
  constructor: (opts = {}) ->
    this.formId = opts.id
    this.obj = opts.for
    this.initObj = if opts.initObj? and opts.initObj then true else false
    this.delegator = opts.delegator
    this.callbackSuccess = opts.callbackSuccess
    this.callbackFailure = opts.callbackFailure
    this.callbackActive = opts.callbackActive
    this.form = this._findForm()
    this.submit = null
    this.submitVal = null
    if this.form?
      this.submit = this.form.querySelector '[type="submit"]'
    if this.submit?
      this.submitVal = this.submit.value
    this.locale = Deps.loco.getLocale()

  getObj: -> this.obj

  render: ->
    if this.initObj
      this._assignAttribs()
      this._handle()
    else if this.form?
      this.fill()
      this._handle()

  fill: (attr = null) ->
    return null if not this.obj?
    return null if not this.obj.constructor.attributes?
    attributes = {}
    if attr?
      attributes[attr] = null
    else
      attributes = this.obj.constructor.attributes
    for name, _ of attributes
      remoteName = this.obj.getAttrRemoteName name
      query = this.form.querySelector "[data-attr=#{remoteName}]"
      continue if query is null
      formEl = query.querySelectorAll "input,textarea,select"
      continue if formEl.length is 0
      if formEl.length is 1
        formEl[0].value = this.obj[name]
        continue
      uniqInputTypes = ArrayUtils.uniq ArrayUtils.map formEl, (e) -> e.getAttribute 'type'
      if uniqInputTypes.length is 1 and uniqInputTypes[0] is 'radio'
        radioEl = CollectionUtils.find formEl, (e) => e.value is String(this.obj[name])
        if radioEl?
          radioEl.checked = true
          continue
      if formEl[0].getAttribute("type") isnt "hidden" and formEl[formEl.length - 1].getAttribute('type') isnt "checkbox"
        continue
      formEl[formEl.length - 1].checked = Boolean(this.obj[name])

  _findForm: ->
    return document.getElementById("#{this.formId}") if this.formId?
    if this.obj?
      objName = this.obj.getIdentity().toLowerCase()
      if this.obj.id?
        document.getElementById "edit_#{objName}_#{this.obj.id}"
      else
        document.getElementById "new_#{objName}"

  _handle: ->
    this.form.addEventListener 'submit', (e) =>
      e.preventDefault()
      return if not this._canBeSubmitted()
      if not this.obj?
        this._submitForm()
        return
      this._assignAttribs()
      this._hideErrors()
      if this.obj.isInvalid()
        this._renderErrors()
        this.delegator[this.callbackFailure]() if this.callbackFailure?
        return
      this._submittingForm false
      clearForm = if this.obj.id? then false else true
      this.obj.save()
      .then (data) =>
        this._alwaysAfterRequest()
        if data.success
          this._handleSuccess data, clearForm
        else
          this.delegator[this.callbackFailure]() if this.callbackFailure?
          this._renderErrors()
      .catch (err) => this._connectionError()

  _canBeSubmitted: ->
    return true unless this.submit?
    return false if DomUtils.hasClass this.submit, 'active'
    return false if DomUtils.hasClass this.submit, 'success'
    return false if DomUtils.hasClass this.submit, 'failure'
    true

  _submitForm: ->
    this._submittingForm()
    url = this.form.getAttribute('action') + '.json'
    data = new FormData this.form
    req = new XMLHttpRequest()
    req.open 'POST', url
    req.setRequestHeader "X-CSRF-Token", document.querySelector("meta[name='csrf-token']")?.content
    req.onload = (e) =>
      this._alwaysAfterRequest()
      this.submit.blur() if this.submit?
      if e.target.status >= 200 and e.target.status < 400
        data = JSON.parse e.target.response
        if data.success
          this._handleSuccess data, this.form.getAttribute("method") is "POST"
        else
          this._renderErrors data.errors
       else if e.target.status >= 500
         this._connectionError()
    req.onerror = =>
      this._alwaysAfterRequest()
      this.submit.blur() if this.submit?
      this._connectionError()
    req.send data

  _handleSuccess: (data, clearForm = true) ->
    val = data.flash?.success ? Deps.I18n[this.locale].ui.form.success
    if this.submit?
      DomUtils.addClass this.submit, 'success'
      this.submit.value = val
    if data.access_token?
      Deps.loco.getWire().setToken(data.access_token)
    if this.callbackSuccess?
      if data.data?
        this.delegator[this.callbackSuccess](data.data)
      else
        this.delegator[this.callbackSuccess]()
      return
    setTimeout =>
      if this.submit?
        this.submit.disabled = false
        DomUtils.removeClass this.submit, 'success'
        this.submit.value = this.submitVal
      selector = ":not([data-loco-not-clear=true])"
      if clearForm
        nodes = this.form.querySelectorAll "input:not([type='submit'])#{selector}, textarea#{selector}"
        for node in nodes
          node.value = ''
    , 5000

  _renderErrors: (remoteErrors = null) ->
    return if this.obj? and not this.obj.errors?
    return if not this.obj? and not remoteErrors?
    data = if remoteErrors? then remoteErrors else this.obj.errors
    for attrib, errors of data
      remoteName = if this.obj? then this.obj.getAttrRemoteName(attrib) else attrib
      if remoteName? and attrib isnt "base"
        # be aware of invalid elements's nesting e.g. "div" inside of "p"
        query = this.form.querySelector "[data-attr=#{remoteName}]"
        continue if query is null
        nodes = query.querySelectorAll ".errors[data-for=#{remoteName}]"
        continue if nodes.length is 0
        for node in nodes
          node.textContent = errors[0]
        continue
      if attrib is "base" and errors.length > 0
        nodes = document.querySelectorAll ".errors[data-for='base']"
        if nodes.length is 1
          nodes[0].textContent = errors[0]
        else if this.submit?
          this.submit.value = errors[0]
    if this.submit?
      if this.submit.value is this.submitVal or this.submit.value is Deps.I18n[this.locale].ui.form.sending
        this.submit.value = Deps.I18n[this.locale].ui.form.errors.invalid_data
      DomUtils.addClass this.submit, 'failure'
    this._showErrors()
    setTimeout =>
      if this.submit?
        this.submit.disabled = false
        DomUtils.removeClass this.submit, 'failure'
        this.submit.value = this.submitVal
      for node in this.form.querySelectorAll('input.invalid, textarea.invalid, select.invalid')
        DomUtils.removeClass node, 'invalid'
    , 1000

  _assignAttribs: ->
    return null if not this.obj.constructor.attributes?
    for name, _ of this.obj.constructor.attributes
      remoteName = this.obj.getAttrRemoteName name
      query = this.form.querySelector "[data-attr=#{remoteName}]"
      continue if query is null
      formEl = query.querySelectorAll "input,textarea,select"
      continue if formEl.length is 0
      if formEl.length is 1
        this.obj.assignAttr name, formEl[0].value
        continue
      uniqInputTypes = ArrayUtils.uniq ArrayUtils.map formEl, (e) -> e.getAttribute 'type'
      if uniqInputTypes.length is 1 and uniqInputTypes[0] is 'radio'
        radioEl = CollectionUtils.find formEl, (e) => e.checked is true
        if radioEl?
          this.obj.assignAttr name, radioEl.value
          continue
      if formEl[0].getAttribute("type") isnt "hidden" and formEl[formEl.length - 1].getAttribute('type') isnt "checkbox"
        continue
      if formEl[formEl.length - 1].checked is true
        this.obj.assignAttr name, formEl[formEl.length - 1].value
      else
        this.obj.assignAttr name, formEl[0].value

  _hideErrors: ->
    for e in this.form.querySelectorAll('.errors')
      if e.textContent.trim().length > 0
        e.textContent = ''
        e.style.display = 'none'

  _showErrors: ->
    for e in this.form.querySelectorAll('.errors')
      if e.textContent.trim().length > 0
        e.style.display = 'block'

  _submittingForm: (hideErrors = true) ->
    if this.submit?
      DomUtils.removeClass this.submit, 'success'
      DomUtils.removeClass this.submit, 'failure'
      DomUtils.addClass this.submit, 'active'
      this.submit.value = Deps.I18n[this.locale].ui.form.sending
    this.delegator[this.callbackActive]() if this.callbackActive?
    this._hideErrors() if hideErrors

  _connectionError: ->
    return unless this.submit?
    DomUtils.removeClass this.submit, 'active'
    DomUtils.addClass this.submit, 'failure'
    this.submit.value = Deps.I18n[this.locale].ui.form.errors.connection
    setTimeout =>
      this.submit.disabled = false
      DomUtils.removeClass this.submit, 'failure'
      this.submit.value = this.submitVal
    , 3000

  _alwaysAfterRequest: ->
    return unless this.submit?
    DomUtils.removeClass this.submit, 'active'

export default Form