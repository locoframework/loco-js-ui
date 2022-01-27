import Deps from "deps.js";
import { connect } from "index";

const connectorThatOverwrites = {
  loco: { getWire: () => {} },
  I18n: {
    en: {
      ui: {
        form: {
          sending: "requesting"
        }
      }
    }
  }
};

const connectorThatAdds = {
  loco: { getWire: () => {} },
  I18n: {
    pl: {
      ui: {
        form: {
          sending: "wysyłam..."
        }
      }
    }
  }
};

describe("I18n", () => {
  it("can be overridden", () => {
    connect(connectorThatOverwrites);
    expect(Object.keys(Deps.I18n.en.ui.form).length).toEqual(1);
    expect(Deps.I18n.en.ui.form.sending).toEqual("requesting");
  });

  it("can be enhanced", () => {
    connect(connectorThatAdds);
    expect(Object.keys(Deps.I18n.en.ui.form).length).toEqual(3);
    expect(Deps.I18n.pl.ui.form.sending).toEqual("wysyłam...");
  });
});
