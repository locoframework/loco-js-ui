const hasClass = (el, className) => {
  if (el.classList != null) return el.classList.contains(className);

  return new RegExp("(^| )" + className + "( |$)", "gi").test(el.className);
};

const addClass = (el, className) => {
  if (el.classList != null) el.classList.add(className);
  else el.className += " " + className;
};

const removeClass = (el, className) => {
  if (el.classList != null) el.classList.remove(className);
  else
    el.className = el.className.replace(
      new RegExp("(^|\\b)" + className.split(" ").join("|") + "(\\b|$)", "gi"),
      " "
    );
};

const getUniqInputTypes = formEl => {
  const types = Array.from(formEl).map(e => e.getAttribute("type"));
  return types.filter((v, i, a) => a.indexOf(v) === i);
};

export { addClass, getUniqInputTypes, hasClass, removeClass };
