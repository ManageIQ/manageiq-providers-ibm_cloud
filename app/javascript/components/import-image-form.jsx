import React, { useMemo, useState } from "react";
import PropTypes from "prop-types";
import { connect } from "react-redux";
import MiqFormRenderer from '@@ddf';
import createSchema from './import-image-form.schema.js';

const BLANK = {value: '-1', label: ''};

const fetchProviders = (kind) => {
  return new Promise((resolve, reject) => {
      var options = [BLANK]

      API.options('/api/providers').then(({data: {supported_providers}}) => {
          var provider_classes = supported_providers;

          API.get('/api/providers?expand=resources&attributes=id,name,type').then(({resources}) => {
              resources.forEach((provider) => {
                  if(provider['id'] === ManageIQ.record.recordId) return;

                  var result = provider_classes.find(provider_class => provider_class['type'] === provider['type']);

                  if (typeof result !== typeof undefined && result['kind'] === kind)
                      options.push({value: provider['id'], label: provider['name']});
              })

              resolve(options);
          })
      })
  })
}

const fetchImages = (provider) => {
    return new Promise((resolve, reject) => {
        API.get('/api/cloud_templates?expand=resources&attributes=id,name&filter[]=ems_id=' + provider).then(({resources}) => {
            let options = resources.map(({id, name}) => ({value: id, label: name}));
            options.unshift(BLANK);
            resolve(options);
        })
    })
}

const fetchDiskTypes = () => {
    return new Promise((resolve, reject) => {
        API.get('/api/cloud_volume_types?expand=resources&attributes=id,name').then(({resources}) => {
            let options = resources.map(({id, name}) => ({value: id, label: name}));
            options.unshift(BLANK);
            resolve(options);
        })
    })
}

const fetchBuckets = (provider) => {
    return new Promise((resolve, reject) => {
        API.get('/api/cloud_object_store_containers?expand=resources&attributes=name,ems_id&filter[]=ems_id=' + provider).then(({resources}) => {
            let options = resources.map(({id, name}) => ({value: id, label: name}));
            options.unshift(BLANK);
            resolve(options);
        })
    })
}

const ImportImageForm = ({ dispatch }) => {
  const [provider, setProvider] = useState('-1');
  const [storage,  setStorage]  = useState('-1');
  const [image,    setImage]    = useState('-1');
  const [bucket,   setBucket]   = useState('-1');
  const [diskType, setDiskType] = useState('-1');
  const [keepOva,  setKeepOva]  = useState(false);

  const providers = fetchProviders('cloud');
  const storages  = fetchProviders('storage');
  const diskTypes = fetchDiskTypes();
  const images    = useMemo(() => fetchImages(provider), [provider]);
  const buckets   = useMemo(() => fetchBuckets(storage), [storage]);

  const initialize = (formOptions) => {
    dispatch({ type: "FormButtons.init",        payload: { newRecord: true, pristine: true } });
    dispatch({ type: "FormButtons.customLabel", payload: __('Import') });
    dispatch({ type: 'FormButtons.callbacks',   payload: { addClicked: () => formOptions.submit() }});
  };

  const submitValues = () => {
      if ([provider, image, storage, bucket].some(item => parseInt(item) === -1))
      {
          window.add_flash("Request ignored due to incomplete input", 'warning');
          return
      }

      const body = {"action": "import", "dst_provider_id": ManageIQ.record.recordId, "src_provider_id": provider, "src_image_id": image, "obj_storage_id": storage, "bucket_id": bucket, "disk_type_id": diskType, 'keep_ova': keepOva};
      API.post('/api/cloud_templates', body).then( ({ results }) => window.add_flash("Request Submitted!"));
  };

  return (<div><div id="ignore_form_changes" /><MiqFormRenderer initialize={initialize} schema={createSchema(providers, provider, setProvider, images, image, setImage, storages, storage, setStorage, buckets, bucket, setBucket, diskTypes, setDiskType, keepOva, setKeepOva)} showFormControls={false} onSubmit={submitValues}/></div>)
};

ImportImageForm.propTypes = {
  dispatch: PropTypes.func.isRequired,
};

export default connect()(ImportImageForm);