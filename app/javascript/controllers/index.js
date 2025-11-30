// Import and register all your controllers

import { application } from "./application"

// Manually import and register each controller
import DrugAutocompleteController from "./drug_autocomplete_controller"

application.register("drug-autocomplete", DrugAutocompleteController)
