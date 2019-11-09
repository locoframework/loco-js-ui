import Deps from "./deps";
import UI from "./ui";
import en from "./locales/en";

const connect = connector => {
  Deps.Env = connector.Env;
  Deps.Utils = connector.Utils;
  Deps.I18n = connector.I18n;
  Deps.I18n.en = { ...Deps.I18n.en, ...en };
};

export { UI, connect };
