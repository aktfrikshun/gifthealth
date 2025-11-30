// Load and register all Stimulus controllers

import { application } from "controllers/application"

// Manually import and register controllers
import DrugAutocompleteController from "controllers/drug_autocomplete_controller"

application.register("drug-autocomplete", DrugAutocompleteController)
