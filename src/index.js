import Deps from "./deps";
import UI from "./ui";

const connect = connector => {
  Deps.Env = connector.Env;
  Deps.I18n = connector.I18n;
  Deps.Utils = connector.Utils;
};

export { Deps, UI, connect };
