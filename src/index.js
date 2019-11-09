import Deps from "./deps";
import UI from "./ui";
import en from "./locales/en";

const connect = connector => {
  Deps.Env = connector.Env;
  Deps.I18n = connector.I18n;
  Deps.I18n.en = { ...en, ...Deps.I18n.en };
};

export { UI, connect };
