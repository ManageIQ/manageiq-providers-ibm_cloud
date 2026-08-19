import React, { useMemo, useState } from "react";
import { useMiqDispatch } from "@@miq-redux/miq-hooks";
import MiqFormRenderer from "@@ddf";
import createSchema from "./import-image-form.schema";
import type {
  OptionType,
  ProvidersResponse,
  ResourcesResponseType,
  FormState,
  FormValues,
  FormOptions,
} from "./import-image-form-types";

const API_PROVIDERS = "/api/providers";
const API_CLOUD_TEMPL = "/api/cloud_templates";
const API_OBJ_CONT = "/api/cloud_object_store_containers";

const fetchProviders = (kind: string): Promise<OptionType[]> => {
  return new Promise((resolve, reject) => {
    const options: OptionType[] = [];

    API.options<ProvidersResponse>(API_PROVIDERS)
      .then(({ data: { supported_providers } }) => {
        const providerClasses = supported_providers;

        API.get<ResourcesResponseType>(
          API_PROVIDERS + "?expand=resources&attributes=id,name,type",
        )
          .then(({ resources }) => {
            resources.forEach((provider) => {
              const result = providerClasses.find(
                (provider_class) => provider_class["type"] === provider["type"],
              );

              if (result && result["kind"] === kind)
                options.push({
                  value: provider["id"],
                  label: provider["name"],
                });
            });

            resolve(options);
          })
          .catch(reject);
      })
      .catch(reject);
  });
};

const fetchImages = (provider?: string | number): Promise<OptionType[]> => {
  return new Promise((resolve, reject) => {
    if (!provider) {
      resolve([]);
      return;
    }
    API.get<ResourcesResponseType>(
      API_CLOUD_TEMPL +
        "?expand=resources&attributes=id,name&filter[]=ems_id=" +
        provider,
    )
      .then(({ resources }) => {
        const options = resources.map(({ id, name }) => ({
          value: id,
          label: name,
        }));
        resolve(options);
      })
      .catch(reject);
  });
};

const fetchBuckets = (provider?: string | number): Promise<OptionType[]> => {
  return new Promise((resolve, reject) => {
    if (!provider) {
      resolve([]);
      return;
    }
    API.get<ResourcesResponseType>(
      API_OBJ_CONT +
        "?expand=resources&attributes=name,ems_id&filter[]=ems_id=" +
        provider,
    )
      .then(({ resources }) => {
        const options = resources.map(({ id, name }) => ({
          value: id,
          label: name,
        }));
        resolve(options);
      })
      .catch(reject);
  });
};

const fetchDiskTypes = (provider: string | number): Promise<OptionType[]> => {
  return new Promise((resolve, reject) => {
    API.get<ResourcesResponseType>(
      API_PROVIDERS +
        "/" +
        provider +
        "/cloud_volume_types?expand=resources&attributes=id,name",
    )
      .then(({ resources }) => {
        const options = resources.map(({ id, name }) => ({
          value: id,
          label: name,
        }));
        resolve(options);
      })
      .catch(reject);
  });
};

const ImportImageForm: React.FC = () => {
  const dispatch = useMiqDispatch();
  const [state, setState] = useState<FormState>({});

  const providers = fetchProviders("cloud");
  const storages = fetchProviders("storage");
  const diskTypes = fetchDiskTypes(ManageIQ.record.recordId);
  const images = useMemo(
    () => fetchImages(state["src_provider_id"]),
    [state["src_provider_id"]],
  );
  const buckets = useMemo(
    () => fetchBuckets(state["obj_storage_id"]),
    [state["obj_storage_id"]],
  );

  const initialize = (formOptions: FormOptions) => {
    // TODO: Modernize Redux - Convert form-buttons-reducer.js to Redux Toolkit slice
    // This would replace manual action types with auto-generated action creators:
    // dispatch(init({ newRecord: true, pristine: true }));
    // dispatch(customLabel(__("Import")));
    // dispatch(callbacks({ addClicked: () => formOptions.submit() }));
    dispatch({
      type: "FormButtons.init",
      payload: { newRecord: true, pristine: true },
    });
    dispatch({ type: "FormButtons.customLabel", payload: __("Import") });
    dispatch({
      type: "FormButtons.callbacks",
      payload: { addClicked: () => formOptions.submit() },
    });
  };

  const onSubmit = (values: FormValues) => {
    API.post(API_CLOUD_TEMPL, {
      ...values,
      action: "import",
      dst_provider_id: ManageIQ.record.recordId,
    }).then(() => add_flash("Image Import Request Submitted!"));
  };

  const onCancel = () => {
    dispatch({ type: "FormButtons.reset" });
  };

  return (
    <div id="ignore_form_changes">
      <MiqFormRenderer
        initialize={initialize}
        schema={createSchema(
          state,
          setState,
          providers,
          storages,
          diskTypes,
          images,
          buckets,
        )}
        showFormControls={false}
        onCancel={onCancel}
        onSubmit={onSubmit}
      />
    </div>
  );
};

export default ImportImageForm;
