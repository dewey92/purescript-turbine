module FahrenheitCelsius.Main where

import Prelude

import Data.Number (fromString)
import Effect (Effect)
import Hareactive.Types (Behavior, Stream, Now)
import Hareactive.Combinators (changes, filterJust, stepper)
import Turbine (Component, modelView, output, runComponent, (</>))
import Turbine.HTML as H

type AppModelOut =
  { fahren :: Behavior Number
  , celsius :: Behavior Number
  }

type AppViewOut =
  { fahrenChange :: Stream String
  , celsiusChange :: Stream String }

parseNumbers :: Stream String -> Stream Number
parseNumbers = filterJust <<< (map fromString)

appModel :: _ -> Now AppModelOut
appModel { fahrenChange, celsiusChange } =
  let
    fahrenToCelsius f = (f - 32.0) / 1.8
    celsiusToFahren c = (c * 9.0) / 5.0 + 32.0
    celsiusNrChange = parseNumbers celsiusChange
    fahrenNrChange = parseNumbers fahrenChange
  in do
    celsius <- stepper 0.0 (celsiusNrChange <> (fahrenToCelsius <$> fahrenNrChange))
    fahren <- stepper 0.0 (fahrenNrChange <> (celsiusToFahren <$> celsiusNrChange))
    pure { fahren, celsius }

appView :: AppModelOut -> Component _ _
appView { celsius, fahren } =
  H.div {} (
    H.div {} (
      H.label {} (H.text "Fahrenheit") </>
      H.input { value: show <$> fahren } `output` (\o -> { fahrenChange: changes o.value })
    ) </>
    H.div {} (
      H.label {} (H.text "Celsius") </>
      H.input { value: show <$> celsius } `output` (\o -> { celsiusChange: changes o.value })
    )
  )

app :: Component {} AppModelOut
app = modelView appModel appView

main :: Effect Unit
main = runComponent "#mount" app
